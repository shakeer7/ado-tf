async function refresh() {
  try {
    const response = await fetch('/api/info', {cache: 'no-store'});
    if (!response.ok) throw new Error('API unavailable');
    const data = await response.json();
    for (const name of ['environment', 'version', 'hostname', 'deployment_timestamp', 'status']) {
      document.getElementById(name).textContent = data[name];
    }
    document.getElementById('dot').className = data.status === 'healthy' ? 'healthy' : 'failed';
  } catch (error) {
    document.getElementById('status').textContent = 'Unavailable';
    document.getElementById('dot').className = 'failed';
  }
}
document.getElementById('refresh').addEventListener('click', refresh);
refresh();
