const fs = require('fs');
const path = require('path');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const root = path.join(__dirname, '..');
const project = fs.readFileSync(
  path.join(root, 'packaging', 'one-file-launcher', 'AetherwakeLauncher.csproj'),
  'utf8'
);
const program = fs.readFileSync(
  path.join(root, 'packaging', 'one-file-launcher', 'Program.cs'),
  'utf8'
);
const workflow = fs.readFileSync(
  path.join(root, '.github', 'workflows', 'desktop-package.yml'),
  'utf8'
);

assert(project.includes('<OutputType>WinExe</OutputType>'),
  'one-file launcher must be a Windows GUI executable');
assert(project.includes('<PublishSingleFile>true</PublishSingleFile>'),
  'one-file launcher must publish as one file');
assert(project.includes('<SelfContained>true</SelfContained>'),
  'one-file launcher must not require a separately installed .NET runtime');
assert(project.includes('<ApplicationIcon>aetherwake.ico</ApplicationIcon>'),
  'one-file launcher must use the Aetherwake icon');
assert(project.includes('LogicalName="Aetherwake.Payload.zip"'),
  'NW.js runtime payload must be embedded in the launcher');

assert(program.includes('Environment.SpecialFolder.LocalApplicationData'),
  'launcher must keep its private extracted runtime out of the download folder');
assert(program.includes('SHA256'),
  'launcher runtime cache must be content-addressed');
assert(program.includes('Embedded runtime contains an unsafe path.'),
  'launcher must reject zip-slip paths');
assert(program.includes('Aetherwake.exe'),
  'launcher must start the verified NW.js executable');

assert(workflow.includes('Aetherwake - The Last Solarpunk Airship.exe'),
  'workflow must publish a recognizable player-facing filename');
assert(workflow.includes('Aetherwake-One-File'),
  'workflow must expose a dedicated one-file artifact');
assert(workflow.includes('scripts/generate-windows-icon.ps1'),
  'workflow must generate the Windows icon before publish');

console.log('Aetherwake one-file Windows launcher contract: PASS');
