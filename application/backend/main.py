"""Small, stateless API. Secret content never leaves the mounted file."""
import json
import logging
import os
import socket
import time
from datetime import datetime, timezone
from pathlib import Path
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

log = logging.getLogger("platform")
logging.basicConfig(level=logging.INFO, format="%(message)s")
app = FastAPI(title="Azure Platform Lab", version="0.1.0", docs_url=None, redoc_url=None)
STARTED = datetime.now(timezone.utc).isoformat()

def secret_ready():
    filename = os.getenv("SECRET_FILE", "")
    if not filename:
        return True
    try:
        return Path(filename).is_file() and Path(filename).stat().st_size > 0
    except OSError:
        return False

@app.middleware("http")
async def request_log(request: Request, call_next):
    begin = time.perf_counter()
    response = await call_next(request)
    log.info(json.dumps({"event": "http_request", "path": request.url.path,
                         "status": response.status_code,
                         "duration_ms": round((time.perf_counter()-begin)*1000, 2)}))
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Content-Security-Policy"] = "default-src 'self'; style-src 'self'; script-src 'self'; object-src 'none'; frame-ancestors 'none'"
    return response

@app.get("/health/live")
def live():
    return {"status": "healthy"}

@app.get("/health/ready")
def ready():
    ok = secret_ready()
    return JSONResponse({"status": "ready" if ok else "not_ready"}, status_code=200 if ok else 503)

@app.get("/api/info")
def info():
    return {"environment": os.getenv("APP_ENV", "local"),
            "version": os.getenv("APP_VERSION", "0.1.0-local"),
            "hostname": os.getenv("POD_NAME", socket.gethostname()),
            "status": "healthy" if secret_ready() else "not_ready",
            "deployment_timestamp": os.getenv("DEPLOYED_AT", STARTED),
            "secret_configured": bool(os.getenv("SECRET_FILE")),
            "secret_available": secret_ready() if os.getenv("SECRET_FILE") else False}

app.mount("/", StaticFiles(directory=Path(__file__).resolve().parents[1] / "frontend", html=True), name="frontend")
