const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const PORT = 8085;
const WEB_DIR = path.join(__dirname, 'build', 'web');

const MIME_TYPES = {
  '.html': 'text/html; charset=UTF-8',
  '.js': 'application/javascript; charset=UTF-8',
  '.mjs': 'application/javascript; charset=UTF-8',
  '.css': 'text/css; charset=UTF-8',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

const server = http.createServer((req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  let reqPath = decodeURI(req.url.split('?')[0]);

  // Proxy API endpoints directly to production WordPress
  if (reqPath.startsWith('/mobile/') || reqPath.startsWith('/voice/') || reqPath.startsWith('/wp-json/')) {
    let targetPath = req.url;
    if (!targetPath.startsWith('/wp-json/')) {
      targetPath = `/wp-json/tc-agents/v1${req.url}`;
    }
    const targetUrl = new URL(`https://tripcosmos.co${targetPath}`);
    const headers = { ...req.headers };
    headers.host = 'tripcosmos.co';
    if (!headers['x-mobile-token'] && process.env.MOBILE_TOKEN) {
      headers['x-mobile-token'] = process.env.MOBILE_TOKEN;
    }

    const proxyReq = https.request(targetUrl, {
      method: req.method,
      headers: headers,
    }, (proxyRes) => {
      res.writeHead(proxyRes.statusCode, {
        ...proxyRes.headers,
        'Access-Control-Allow-Origin': '*',
      });
      proxyRes.pipe(res);
    });

    proxyReq.on('error', (e) => {
      res.writeHead(502, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: e.message }));
    });

    req.pipe(proxyReq);
    return;
  }

  if (reqPath === '/' || reqPath === '') reqPath = '/index.html';

  let filePath = path.join(WEB_DIR, reqPath);

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      filePath = path.join(WEB_DIR, 'index.html');
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    fs.readFile(filePath, (readErr, content) => {
      if (readErr) {
        res.writeHead(500);
        res.end('Server Error');
        return;
      }
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content);
    });
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`X-Agents Web server running at http://localhost:${PORT}`);
});
