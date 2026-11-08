# Exact Python patch; dependency lock includes hashes. Upgrade through reviewed CI.
FROM python:3.15.2-slim-trixie@sha256:e97b88e416c3c01eb427b21fd8cd3ebf006e6ee38afcfcc3cae1c54ee2ab0a75
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir --require-hashes -r requirements.txt && groupadd -g 10001 app && useradd -r -u 10001 -g app app
COPY --chown=10001:10001 backend ./backend
COPY --chown=10001:10001 frontend ./frontend
USER 10001:10001
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health/live',timeout=2)"]
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8080", "--no-access-log"]
