// Simple proxy server for AssemblyAI Universal Streaming v3 token generation
// Run with: node proxy_server.js
// This is needed because AssemblyAI's token endpoint doesn't allow CORS from browsers

const http = require('http');
const https = require('https');

const PORT = 3001;

const server = http.createServer((req, res) => {
  // Enable CORS for all origins
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Handle preflight OPTIONS request  
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Handle both GET and POST to /token for flexibility
  if (req.url === '/token' || req.url.startsWith('/token?')) {
    const apiKey = req.headers.authorization;

    if (!apiKey) {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Missing Authorization header' }));
      return;
    }

    // Universal Streaming v3 uses GET request to streaming.assemblyai.com/v3/token
    // expires_in_seconds must be between 1 and 600 (max 10 minutes)
    const options = {
      hostname: 'streaming.assemblyai.com',
      port: 443,
      path: '/v3/token?expires_in_seconds=600',
      method: 'GET',
      headers: {
        'Authorization': apiKey,
      }
    };

    console.log(`Getting v3 token for API key: ${apiKey.substring(0, 8)}...`);

    const proxyReq = https.request(options, (proxyRes) => {
      let data = '';
      proxyRes.on('data', chunk => { data += chunk; });
      proxyRes.on('end', () => {
        console.log(`Token response: ${proxyRes.statusCode} - ${data.substring(0, 200)}`);
        res.writeHead(proxyRes.statusCode, { 'Content-Type': 'application/json' });
        res.end(data);
      });
    });

    proxyReq.on('error', (e) => {
      console.error(`Request error: ${e.message}`);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: e.message }));
    });

    proxyReq.end();
  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

server.listen(PORT, () => {
  console.log(`CORS Proxy server running at http://localhost:${PORT}`);
  console.log(`GET or POST /token - Get v3 streaming token from AssemblyAI`);
  console.log(`\nUsing Universal Streaming v3 endpoint: streaming.assemblyai.com/v3/token`);
  console.log(`Token expires in: 600 seconds (10 minutes)`);
});
