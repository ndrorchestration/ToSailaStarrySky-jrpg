const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const DEST = path.join(ROOT, 'build', 'runtime-app');

const REQUIRED_FILES = Object.freeze([
  'index-embedded.html',
  'index.html',
  'aetherwake.js',
  'p5.min.js',
  'embedded-fonts.css',
  'icon.svg',
]);

const REQUIRED_DIRECTORIES = Object.freeze([
  'modules',
]);

const MANIFEST_KEYS = Object.freeze([
  'name',
  'version',
  'description',
  'main',
  'window',
  'webkit',
  'js-flags',
  'chromium-args',
]);

const FORBIDDEN_RUNTIME_ENTRIES = Object.freeze([
  'node_modules',
  'tests',
  'docs',
  '.github',
  'scripts',
  'build',
  'nw-package',
  'standalone',
]);

function fail(message) {
  throw new Error('DESKTOP_RUNTIME_STAGE_FAIL: ' + message);
}

function copyRequiredFile(relativePath) {
  const source = path.join(ROOT, relativePath);
  const destination = path.join(DEST, relativePath);
  if (!fs.existsSync(source) || !fs.statSync(source).isFile()) {
    fail('required file missing: ' + relativePath);
  }
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.copyFileSync(source, destination);
}

function copyRequiredDirectory(relativePath) {
  const source = path.join(ROOT, relativePath);
  const destination = path.join(DEST, relativePath);
  if (!fs.existsSync(source) || !fs.statSync(source).isDirectory()) {
    fail('required directory missing: ' + relativePath);
  }
  fs.cpSync(source, destination, { recursive: true });
}

function writeRuntimeManifest() {
  const sourcePath = path.join(ROOT, 'package.json');
  const source = JSON.parse(fs.readFileSync(sourcePath, 'utf8'));
  const runtime = {};

  for (const key of MANIFEST_KEYS) {
    if (Object.prototype.hasOwnProperty.call(source, key)) {
      runtime[key] = source[key];
    }
  }

  if (runtime.main !== 'index-embedded.html') {
    fail('runtime manifest main must remain index-embedded.html');
  }
  if (!runtime.window || runtime.window.icon !== 'icon.svg') {
    fail('runtime manifest must preserve icon.svg window icon');
  }

  fs.writeFileSync(
    path.join(DEST, 'package.json'),
    JSON.stringify(runtime, null, 2) + '\n',
    'utf8'
  );
}

function walkFiles(directory) {
  const output = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) output.push(...walkFiles(full));
    else if (entry.isFile()) output.push(full);
  }
  return output;
}

function verifyLocalHtmlReferences(relativePath) {
  const htmlPath = path.join(DEST, relativePath);
  const html = fs.readFileSync(htmlPath, 'utf8');
  const matches = html.matchAll(/(?:src|href)=["']([^"']+)["']/g);

  for (const match of matches) {
    const reference = match[1];
    if (!reference ||
        reference.startsWith('http://') ||
        reference.startsWith('https://') ||
        reference.startsWith('data:') ||
        reference.startsWith('#')) {
      continue;
    }

    const clean = reference.split(/[?#]/)[0];
    if (!clean) continue;
    const resolved = path.resolve(path.dirname(htmlPath), clean);
    if (!resolved.startsWith(DEST + path.sep) && resolved !== DEST) {
      fail(relativePath + ' reference escapes staged runtime: ' + reference);
    }
    if (!fs.existsSync(resolved)) {
      fail(relativePath + ' local reference missing from staged runtime: ' + reference);
    }
  }
}

function verifyStage() {
  for (const relativePath of REQUIRED_FILES) {
    const target = path.join(DEST, relativePath);
    if (!fs.existsSync(target) || !fs.statSync(target).isFile()) {
      fail('staged required file missing: ' + relativePath);
    }
  }

  for (const relativePath of REQUIRED_DIRECTORIES) {
    const target = path.join(DEST, relativePath);
    if (!fs.existsSync(target) || !fs.statSync(target).isDirectory()) {
      fail('staged required directory missing: ' + relativePath);
    }
  }

  for (const entry of FORBIDDEN_RUNTIME_ENTRIES) {
    if (fs.existsSync(path.join(DEST, entry))) {
      fail('development-only entry leaked into staged runtime: ' + entry);
    }
  }

  const manifest = JSON.parse(
    fs.readFileSync(path.join(DEST, 'package.json'), 'utf8')
  );
  if (manifest.devDependencies || manifest.scripts || manifest.dependencies) {
    fail('runtime manifest contains dependency or development script metadata');
  }

  verifyLocalHtmlReferences('index-embedded.html');
  verifyLocalHtmlReferences('index.html');

  const files = walkFiles(DEST);
  const bytes = files.reduce((sum, file) => sum + fs.statSync(file).size, 0);
  if (bytes <= 0) fail('staged runtime is empty');
  if (bytes > 20 * 1024 * 1024) {
    fail('staged runtime unexpectedly exceeds 20 MiB: ' + bytes);
  }

  return {
    files: files.length,
    bytes,
  };
}

fs.rmSync(DEST, { recursive: true, force: true });
fs.mkdirSync(DEST, { recursive: true });

for (const file of REQUIRED_FILES) copyRequiredFile(file);
for (const directory of REQUIRED_DIRECTORIES) copyRequiredDirectory(directory);
writeRuntimeManifest();

const summary = verifyStage();
console.log(
  'Aetherwake desktop runtime staged:',
  summary.files + ' files,',
  summary.bytes + ' bytes'
);
