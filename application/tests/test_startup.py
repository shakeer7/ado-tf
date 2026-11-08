"""Exercise an actual Uvicorn process and HTTP socket, then shut it down."""
import os
import socket
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

def test_uvicorn_startup_and_health():
    with socket.socket() as reservation:
        reservation.bind(('127.0.0.1',0)); port=reservation.getsockname()[1]
    env=dict(os.environ,APP_ENV='startup-test')
    process=subprocess.Popen([sys.executable,'-m','uvicorn','backend.main:app','--host','127.0.0.1','--port',str(port),'--no-access-log'],cwd=Path(__file__).parents[1],env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    try:
        for _ in range(100):
            try:
                with urllib.request.urlopen(f'http://127.0.0.1:{port}/health/ready',timeout=1) as response:
                    assert response.status==200
                break
            except OSError:
                assert process.poll() is None, 'Uvicorn exited before becoming ready'
                time.sleep(.1)
        else: raise AssertionError('Uvicorn did not become ready')
    finally:
        process.terminate()
        try: process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill(); process.wait(timeout=5)
