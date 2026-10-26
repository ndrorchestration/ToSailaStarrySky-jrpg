/**
 * Fail-closed guard for the *specific* historical NW.js/NSIS distribution
 * workflow. This is NOT a repository-wide secret scan or malware adjudication.
 * It prevents accidental reactivation without an explicit PR that changes
 * both this evidence gate and the disabled workflow.
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
const file = fileURLToPath(new URL('../.github/workflows/desktop-package.yml', import.meta.url));
const source = readFileSync(file, 'utf8');
const text = source.split('\n').filter(line => !/^\s*#/.test(line)).join('\n');
const rules = [
  ['explicit historic hold', source.includes('# SECURITY HOLD')],
  ['no push/tag event', !/^\s*(?:push|tags):/m.test(text)],
  ['manual attempts are gated', /^\s*workflow_dispatch:\s*$/m.test(text) &&
    /if:\s*github\.event_name == 'workflow_dispatch'/m.test(text)],
  ['refusal is a failed action', /Refuse manual execution[\s\S]*?exit 1/m.test(text)],
  ['repository token is read only', /permissions:\s*\n\s*contents:\s*read\s*\n/m.test(text) &&
    !/contents:\s*write/m.test(text)],
  ['no release publishing action', !/softprops\/action-gh-release|gh\s+release\s+create|publish\s+verified\s+windows\s+release/i.test(text)],
  ['no legacy Windows build invocation', !/makensis|npm\s+run\s+package:windows|Start-Process|choco\s+install\s+nsis/i.test(text)],
  ['manual flow is inert except refusal', !/uses:\s*(?:actions\/checkout|actions\/setup-node)/i.test(text)],
];
let failed = false;
for (const [label, ok] of rules) {
  console.log(`LEGACY_RELEASE_HOLD_${ok ? 'PASS' : 'FAIL'}: ${label}`);
  if (!ok) failed = true;
}
if (failed) process.exitCode = 1;
