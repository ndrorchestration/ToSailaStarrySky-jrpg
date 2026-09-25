'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

function sha256File(file) {
  const hash = crypto.createHash('sha256');
  const fd = fs.openSync(file, 'r');
  const buffer = Buffer.allocUnsafe(1024 * 1024);
  try {
    let count;
    while ((count = fs.readSync(fd, buffer, 0, buffer.length, null)) > 0) {
      hash.update(buffer.subarray(0, count));
    }
  } finally {
    fs.closeSync(fd);
  }
  return hash.digest('hex');
}

function fingerprintDirectory(root) {
  const absoluteRoot = path.resolve(root);
  const records = [];

  function visit(current, relative) {
    const entries = fs.readdirSync(current, { withFileTypes: true })
      .sort((a, b) => a.name.localeCompare(b.name, 'en'));
    for (const entry of entries) {
      const full = path.join(current, entry.name);
      const rel = relative ? path.join(relative, entry.name) : entry.name;
      const normalized = rel.split(path.sep).join('/');
      const stat = fs.lstatSync(full);
      if (stat.isSymbolicLink()) {
        throw new Error('symbolic links are not allowed in Chapter 1 package fingerprint: ' + normalized);
      }
      if (entry.isDirectory()) {
        visit(full, rel);
      } else if (entry.isFile()) {
        records.push({
          path: normalized,
          size: stat.size,
          sha256: sha256File(full),
        });
      } else {
        throw new Error('unsupported filesystem entry in Chapter 1 package: ' + normalized);
      }
    }
  }

  visit(absoluteRoot, '');
  const overall = crypto.createHash('sha256');
  for (const record of records.sort((a, b) => a.path.localeCompare(b.path, 'en'))) {
    overall.update(record.path, 'utf8');
    overall.update('\0');
    overall.update(String(record.size), 'utf8');
    overall.update('\0');
    overall.update(record.sha256, 'ascii');
    overall.update('\n');
  }
  return overall.digest('hex');
}

if (require.main === module) {
  const root = process.argv[2];
  if (!root) {
    console.error('usage: node scripts/hash-chapter1-package.js <directory>');
    process.exit(2);
  }
  try {
    console.log(fingerprintDirectory(root));
  } catch (err) {
    console.error(err && err.message ? err.message : String(err));
    process.exit(1);
  }
}

module.exports = { fingerprintDirectory };
