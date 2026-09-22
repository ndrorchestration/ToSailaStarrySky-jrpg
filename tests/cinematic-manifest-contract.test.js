const fs = require('fs');
const path = require('path');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const root = path.join(__dirname, '..');
const cinematicDir = path.join(root, 'assets', 'cinematics');
const schemaPath = path.join(cinematicDir, 'cinematic-manifest.schema.json');
const templatePath = path.join(cinematicDir, 'example-cinematic.manifest.template.json');

assert(fs.existsSync(schemaPath), 'cinematic manifest schema is missing');
assert(fs.existsSync(templatePath), 'cinematic manifest template is missing');

const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));
const template = JSON.parse(fs.readFileSync(templatePath, 'utf8'));

const required = [
  'id', 'version', 'file', 'storySequence', 'trigger', 'skippable',
  'replayable', 'blocksProgression', 'fallback', 'audio', 'subtitles', 'nextState'
];

assert(Array.isArray(schema.required), 'cinematic schema required list is missing');
for (const key of required) {
  assert(schema.required.includes(key), `cinematic schema must require ${key}`);
  assert(Object.prototype.hasOwnProperty.call(template, key), `cinematic template must include ${key}`);
}

assert(schema.properties.blocksProgression.const === false,
  'cinematic schema must forbid video from owning progression');
assert(template.blocksProgression === false,
  'cinematic template must default blocksProgression=false');
assert(/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(template.id),
  'cinematic template id must be kebab-case');
assert(/^(?:[a-z0-9]+(?:-[a-z0-9]+)*\/)*[a-z0-9]+(?:-[a-z0-9]+)*\.mp4$/.test(template.file),
  'cinematic template file must be kebab-case MP4');
assert(['still', 'in-engine', 'still-or-in-engine'].includes(template.fallback.type),
  'cinematic template fallback type is invalid');
assert(['baked', 'hybrid', 'runtime-controlled', 'baked-or-runtime'].includes(template.audio.mode),
  'cinematic template audio mode is invalid');

function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) return walk(full);
    return [full];
  });
}

const manifests = walk(cinematicDir).filter((file) =>
  file.endsWith('.json') &&
  !file.endsWith('cinematic-manifest.schema.json') &&
  !file.endsWith('example-cinematic.manifest.template.json')
);

for (const file of manifests) {
  const manifest = JSON.parse(fs.readFileSync(file, 'utf8'));
  for (const key of required) {
    assert(Object.prototype.hasOwnProperty.call(manifest, key),
      `${path.relative(root, file)} missing required field ${key}`);
  }
  assert(manifest.blocksProgression === false,
    `${path.relative(root, file)} must set blocksProgression=false`);
  assert(/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(manifest.id),
    `${path.relative(root, file)} id must be kebab-case`);
  assert(/^(?:[a-z0-9]+(?:-[a-z0-9]+)*\/)*[a-z0-9]+(?:-[a-z0-9]+)*\.mp4$/.test(manifest.file),
    `${path.relative(root, file)} file must be kebab-case MP4`);
  const expectedBase = path.basename(file, '.json');
  assert(expectedBase === manifest.id,
    `${path.relative(root, file)} basename must match manifest id`);
}

console.log(`Aetherwake cinematic manifest contract: PASS (${manifests.length} runtime manifests)`);
