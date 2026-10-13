#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const cp = require('node:child_process');

const root = path.resolve(__dirname, '../..');
const queue = JSON.parse(fs.readFileSync(path.join(root, 'docs/autonomy/QUEUE.json'), 'utf8'));
const stateDir = path.join(root, '.autonomy');
const statePath = path.join(stateDir, 'state.json');
const args = process.argv.slice(2);
const dry = args.includes('--dry-run');
const retryArg = args.find((arg) => arg.startsWith('--retry-blocked='));
const retryId = retryArg ? retryArg.slice('--retry-blocked='.length).trim() : null;
const OUTPUT_TAIL_CHARS = 12000;

function cmd(command, commandArgs) {
  return cp.spawnSync(command, commandArgs, {
    cwd: root,
    encoding: 'utf8',
    shell: process.platform === 'win32',
    timeout: 30000,
  });
}

function tailText(value) {
  const text = typeof value === 'string' ? value : '';
  return text.length <= OUTPUT_TAIL_CHARS ? text : text.slice(-OUTPUT_TAIL_CHARS);
}

function fatal(message) {
  console.error('BLOCKED: ' + message);
  process.exitCode = 2;
}

function baseEligible(task, state) {
  return (
    task.status === 'READY' &&
    !task.requires_approval &&
    !state.completed[task.id] &&
    task.depends_on.every((id) => state.completed[id] === 'PASS')
  );
}

function selectTask(state) {
  if (retryId) {
    const task = queue.tasks.find((candidate) => candidate.id === retryId);
    if (!task) {
      fatal('Unknown retry task: ' + retryId);
      return null;
    }
    const priorBlocked = state.attempts.some(
      (attempt) => attempt.id === retryId && attempt.phase === 'BLOCKED'
    );
    if (!priorBlocked) {
      fatal('Explicit retry requires a preserved prior BLOCKED attempt: ' + retryId);
      return null;
    }
    if (!baseEligible(task, state)) {
      fatal('Retry task is not currently eligible under queue dependencies/approval gates: ' + retryId);
      return null;
    }
    return task;
  }

  return queue.tasks
    .filter(
      (task) =>
        baseEligible(task, state) &&
        !state.attempts.some((attempt) => attempt.id === task.id)
    )
    .sort((a, b) => a.priority - b.priority)[0];
}

const branch = cmd('git', ['branch', '--show-current']);
const status = cmd('git', ['status', '--porcelain']);

if (branch.status !== 0 || status.status !== 0) {
  fatal('Git unavailable');
} else if (['', 'main', 'master'].includes(branch.stdout.trim())) {
  fatal('Refuse default or detached branch');
} else if (status.stdout.trim()) {
  fatal('Dirty worktree; preserve user changes');
} else {
  const state = fs.existsSync(statePath)
    ? JSON.parse(fs.readFileSync(statePath, 'utf8'))
    : { schema: 1, completed: {}, attempts: [] };
  const selected = selectTask(state);

  if (!selected) {
    if (!process.exitCode) {
      console.log('NO_ELIGIBLE_TASK; pending approvals/dependencies, preserved attempts, or queue exhausted');
    }
  } else if (dry) {
    console.log(
      JSON.stringify(
        {
          selected,
          branch: branch.stdout.trim(),
          mode: retryId ? 'DRY_RUN_EXPLICIT_RETRY' : 'DRY_RUN',
        },
        null,
        2
      )
    );
  } else {
    fs.mkdirSync(stateDir, { recursive: true });
    const lock = path.join(stateDir, 'lock');
    let fd;
    try {
      fd = fs.openSync(lock, 'wx');
    } catch {
      fatal('Another controller lock exists; inspect before retry');
      process.exit(2);
    }

    try {
      const sha = cmd('git', ['rev-parse', 'HEAD']).stdout.trim();
      const prompt =
        'Aetherwake task ' +
        selected.id +
        ': ' +
        selected.title +
        '\nRead AGENTS.md and docs/autonomy/README.md. Never merge/push/release or change canon/approval. Work only in this branch and provide exact evidence. Stop after this one task.';
      const startedAt = new Date().toISOString();
      const startedMs = Date.now();
      const result = cp.spawnSync(
        'codex',
        ['exec', '--sandbox', 'workspace-write', '-'],
        {
          cwd: root,
          encoding: 'utf8',
          input: prompt,
          shell: process.platform === 'win32',
          timeout: 45 * 60 * 1000,
          maxBuffer: 8 * 1024 * 1024,
        }
      );
      const attempt = {
        id: selected.id,
        base_sha: sha,
        started_at: startedAt,
        finished_at: new Date().toISOString(),
        duration_ms: Date.now() - startedMs,
        explicit_retry: Boolean(retryId),
        exit_status: result.status,
        signal: result.signal || null,
        timed_out: Boolean(result.error && result.error.code === 'ETIMEDOUT'),
        phase: result.status === 0 ? 'REVIEW_REQUIRED' : 'BLOCKED',
        error: (result.error && result.error.message) || null,
        stdout_tail: tailText(result.stdout),
        stderr_tail: tailText(result.stderr),
      };
      state.attempts.push(attempt);
      fs.writeFileSync(statePath, JSON.stringify(state, null, 2) + '\n');
      console.log(JSON.stringify(attempt));
      if (result.status !== 0) process.exitCode = 1;
    } finally {
      fs.closeSync(fd);
      fs.unlinkSync(lock);
    }
  }
}
