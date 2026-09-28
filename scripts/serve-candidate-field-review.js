'use strict';
const fs = require('fs');
const http = require('http');
const path = require('path');
const { spawn } = require('child_process');
const { URL } = require('url');

const root = path.resolve(__dirname, '..');
const port = Number(process.env.AETHERWAKE_REVIEW_PORT || 8098);
const target = `http://127.0.0.1:${port}/index-embedded.html?candidateFieldArt=1`;

function contentType(file) {
  const ext = path.extname(file).toLowerCase();
  return {
    '.html':'text/html; charset=utf-8',
    '.js':'text/javascript; charset=utf-8',
    '.css':'text/css; charset=utf-8',
    '.json':'application/json; charset=utf-8',
    '.png':'image/png',
    '.jpg':'image/jpeg',
    '.jpeg':'image/jpeg',
    '.mp3':'audio/mpeg',
    '.wav':'audio/wav',
  }[ext] || 'application/octet-stream';
}

const server = http.createServer((req,res) => {
  const parsed = new URL(req.url, target);
  const requested = decodeURIComponent(parsed.pathname === '/' ? '/index-embedded.html' : parsed.pathname);
  const full = path.resolve(root, requested.replace(/^\/+/, ''));
  if (!full.startsWith(root + path.sep) && full !== root) {
    res.writeHead(403); res.end('Forbidden'); return;
  }
  fs.readFile(full, (error,data) => {
    if (error) { res.writeHead(404); res.end('Not found'); return; }
    res.writeHead(200, {'Content-Type':contentType(full), 'Cache-Control':'no-store'});
    res.end(data);
  });
});

server.listen(port, '127.0.0.1', () => {
  console.log('AETHERWAKE_CANDIDATE_FIELD_REVIEW=' + target);
  if (process.platform === 'win32') {
    const child = spawn('cmd.exe', ['/c', 'start', '', target], { detached:true, stdio:'ignore' });
    child.unref();
  }
  console.log('Press Ctrl+C to stop the local review server.');
});
