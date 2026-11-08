import importlib.util
from pathlib import Path
from fastapi.testclient import TestClient
spec = importlib.util.spec_from_file_location("platform_app", Path(__file__).parents[1] / "backend/main.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
client = TestClient(module.app)

def test_health_and_frontend():
    assert client.get('/health/live').json() == {'status':'healthy'}
    assert client.get('/health/ready').status_code == 200
    assert 'One platform.' in client.get('/').text
    assert client.get('/app.js').status_code == 200

def test_environment_and_identity(monkeypatch):
    monkeypatch.setenv('APP_ENV','stage')
    monkeypatch.setenv('APP_VERSION','release-abc123')
    monkeypatch.setenv('POD_NAME','sample-test-xyz')
    monkeypatch.setenv('DEPLOYED_AT','2026-11-07T00:00:00Z')
    data = client.get('/api/info').json()
    assert data['environment'] == 'stage'
    assert data['version'] == 'release-abc123'
    assert data['hostname'] == 'sample-test-xyz'
    assert data['deployment_timestamp'] == '2026-11-07T00:00:00Z'

def test_secret_readiness_never_exposes_value(monkeypatch,tmp_path):
    secret = tmp_path / 'secret'
    monkeypatch.setenv('SECRET_FILE',str(secret))
    assert client.get('/health/ready').status_code == 503
    secret.write_text('test-value-never-returned')
    assert client.get('/health/ready').status_code == 200
    response = client.get('/api/info')
    assert response.json()['secret_available'] is True
    assert 'test-value-never-returned' not in response.text

def test_security_headers():
    result = client.get('/')
    assert result.headers['X-Content-Type-Options'] == 'nosniff'
    assert "frame-ancestors 'none'" in result.headers['Content-Security-Policy']
