const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function loadBrowserModule(relativePath, globals = {}) {
  const sandbox = Object.assign({
    console,
    setTimeout,
    clearTimeout,
    setInterval,
    clearInterval,
  }, globals);

  if (!sandbox.window) sandbox.window = sandbox;
  if (!sandbox.globalThis) sandbox.globalThis = sandbox;
  sandbox.module = { exports: {} };
  sandbox.exports = sandbox.module.exports;

  const filename = path.resolve(__dirname, '..', relativePath);
  const source = fs.readFileSync(filename, 'utf8');
  vm.createContext(sandbox);
  new vm.Script(source, { filename }).runInContext(sandbox);
  return sandbox;
}

function fakeStorage(initialEntries = {}) {
  const entries = new Map();
  Object.keys(initialEntries).forEach(key => {
    entries.set(String(key), String(initialEntries[key]));
  });

  return {
    get length() {
      return entries.size;
    },
    key(index) {
      if (!Number.isInteger(index) || index < 0 || index >= entries.size) return null;
      return Array.from(entries.keys())[index] || null;
    },
    getItem(key) {
      const normalized = String(key);
      return entries.has(normalized) ? entries.get(normalized) : null;
    },
    setItem(key, value) {
      entries.set(String(key), String(value));
    },
    removeItem(key) {
      entries.delete(String(key));
    },
    clear() {
      entries.clear();
    },
  };
}

module.exports = {
  fakeStorage,
  loadBrowserModule,
};
