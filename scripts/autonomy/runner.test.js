'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const q = JSON.parse(
  fs.readFileSync(path.join(__dirname, '../../docs/autonomy/QUEUE.json'), 'utf8')
);
const runner = fs.readFileSync(path.join(__dirname, 'runner.js'), 'utf8');

assert.equal(q.policy, 'FAIL_CLOSED');
const ids = new Set(q.tasks.map((task) => task.id));
assert.equal(ids.size, q.tasks.length);

for (const task of q.tasks) {
  assert.ok(task.id && task.title);
  assert.ok(['READY', 'BLOCKED_APPROVAL'].includes(task.status));
  for (const dependency of task.depends_on) assert.ok(ids.has(dependency), dependency);
  if (task.requires_approval) assert.equal(task.status, 'BLOCKED_APPROVAL');
}

assert.match(runner, /--retry-blocked=/);
assert.match(runner, /prior BLOCKED attempt/);
assert.match(runner, /explicit_retry/);
assert.match(runner, /timed_out/);
assert.match(runner, /stdout_tail/);
assert.match(runner, /stderr_tail/);
assert.match(runner, /OUTPUT_TAIL_CHARS = 12000/);
assert.match(runner, /45 \* 60 \* 1000/);
assert.match(runner, /attempt\.phase === 'BLOCKED'/);
assert.doesNotMatch(runner, /while\s*\(/);

console.log('autonomy queue/recovery contract PASS: ' + ids.size + ' tasks');
