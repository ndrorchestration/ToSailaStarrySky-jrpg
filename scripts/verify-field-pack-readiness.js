'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const cp = require('child_process');

const root = path.resolve(__dirname, '..');
const manifestPath = path.join(root, 'assets', 'characters', 'v1', 'manifest.json');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const requireComplete = process.argv.includes('--require-complete');
const requireReady = process.argv.includes('--require-ready');
const requireEvidence = process.argv.includes('--require-evidence');
const ids = process.argv.slice(2).filter(v => !v.startsWith('--'));
const targets = ids.length ? ids : ['ender', 'ionia'];

const FIELD_CELL = Object.freeze({ width: 64, height: 96 });
const EXPECTED_ACTIONS = Object.freeze({ idle: 8, walk: 6, talk: 4, focus: 6, attack: 8 });
const ACTION_NAMES = Object.freeze(Object.keys(EXPECTED_ACTIONS));
const ADMISSION_SCHEMA = 'AETHERWAKE_FIELD_ART_ADMISSION_V1';
const evidenceManifestPath = path.join(root, 'visual-evidence', 'manifest.json');
const likenessAuthorityPath = path.join(root, 'docs', 'PROTAGONIST_VISUAL_ALIGNMENT_V1.md');

function gitText(args) {
  const result = cp.spawnSync('git', args, { cwd: root, encoding: 'utf8' });
  if (result.status !== 0) return null;
  return result.stdout.trim();
}

function currentGitHead() {
  const head = gitText(['rev-parse', 'HEAD']);
  return head && /^[0-9a-f]{40}$/i.test(head) ? head.toLowerCase() : null;
}

function admissionTransitionMatches(reviewedHead) {
  const current = currentGitHead();
  if (!current || typeof reviewedHead !== 'string' || !/^[0-9a-f]{40}$/i.test(reviewedHead)) {
    return { valid: false, mode: 'INVALID_HEAD', currentHead: current, parentHead: null, changedFiles: [] };
  }
  const reviewed = reviewedHead.toLowerCase();

  const allowed = new Set([
    'assets/characters/v1/manifest.json',
    'assets/characters/v1/admission/ender.json',
    'assets/characters/v1/admission/ionia.json'
  ]);

  // Before the bounded admission commit is created, the working tree may carry
  // only the receipt/manifest changes while HEAD remains the exact reviewed candidate.
  if (current === reviewed) {
    const status = gitText(['status', '--porcelain']);
    if (status === null) {
      return { valid: false, mode: 'STATUS_UNAVAILABLE', currentHead: current, parentHead: null, changedFiles: [] };
    }
    const changedFiles = status
      ? status.split(/\r?\n/).filter(Boolean).map(line => line.slice(3).trim())
      : [];
    const valid = changedFiles.every(file => allowed.has(file));
    return {
      valid,
      mode: valid ? 'REVIEWED_HEAD_WORKTREE' : 'UNBOUNDED_REVIEWED_WORKTREE',
      currentHead: current,
      parentHead: null,
      changedFiles
    };
  }

  const parent = gitText(['rev-parse', 'HEAD^']);
  const status = gitText(['status', '--porcelain']);
  if (!parent || parent.toLowerCase() !== reviewed || status === null || status.length > 0) {
    return {
      valid: false,
      mode: 'NOT_BOUNDED_CHILD',
      currentHead: current,
      parentHead: parent ? parent.toLowerCase() : null,
      changedFiles: []
    };
  }

  const diff = gitText(['diff', '--name-only', parent, current]);
  if (diff === null) {
    return { valid: false, mode: 'DIFF_UNAVAILABLE', currentHead: current, parentHead: parent.toLowerCase(), changedFiles: [] };
  }
  const changedFiles = diff ? diff.split(/\r?\n/).filter(Boolean) : [];
  const valid = changedFiles.length > 0 && changedFiles.every(file => allowed.has(file));
  return {
    valid,
    mode: valid ? 'BOUNDED_ADMISSION_CHILD' : 'UNBOUNDED_CHILD',
    currentHead: current,
    parentHead: parent.toLowerCase(),
    changedFiles
  };
}

function sha256File(file) {
  if (!file || !fs.existsSync(file)) return null;
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

function pngInfo(file) {
  if (!fs.existsSync(file)) return { exists: false };
  const buf = fs.readFileSync(file);
  const signature = buf.subarray(0, 8).toString('hex');
  if (signature !== '89504e470d0a1a0a' || buf.length < 26) return { exists: true, png: false };
  return {
    exists: true,
    png: true,
    width: buf.readUInt32BE(16),
    height: buf.readUInt32BE(20),
    colorType: buf[25],
    bytes: buf.length,
  };
}

function sameActions(fieldStrips) {
  const expected = [...ACTION_NAMES].sort();
  const names = Object.keys(fieldStrips || {}).sort();
  return names.length === expected.length && names.every((name, index) => name === expected[index]);
}

function inspectAdmissionEvidence(id, stripHashes, actualHead, actualEvidenceManifestSha256) {
  const relativePath = path.join('assets', 'characters', 'v1', 'admission', id + '.json');
  const file = path.join(root, relativePath);
  if (!fs.existsSync(file)) return { path: relativePath.replace(/\\/g, '/'), exists: false, valid: false };
  try {
    const receipt = JSON.parse(fs.readFileSync(file, 'utf8'));
    const silhouette = receipt.silhouetteRecognition || {};
    const rawParticipants = Array.isArray(silhouette.participants) ? silhouette.participants : [];
    const silhouetteIds = new Set();
    let silhouetteCorrect = 0;
    let silhouetteEvidenceValid = rawParticipants.length >= 5;
    for (const participant of rawParticipants) {
      if (!participant || typeof participant.id !== 'string' || !participant.id.trim() ||
          silhouetteIds.has(participant.id) ||
          participant.independentOfImplementation !== true ||
          typeof participant.correct !== 'boolean') {
        silhouetteEvidenceValid = false;
        continue;
      }
      silhouetteIds.add(participant.id);
      if (participant.correct) silhouetteCorrect++;
    }
    const silhouetteRate = rawParticipants.length ? silhouetteCorrect / rawParticipants.length : 0;
    silhouetteEvidenceValid = silhouetteEvidenceValid &&
      silhouetteIds.size === rawParticipants.length &&
      silhouetteRate >= 0.80;

    const runtime = receipt.runtimeReview || {};
    const likeness = receipt.likenessReview || {};
    const projectLikeness = manifest.likenessAuthority || {};
    const characterRecord = manifest.characters && manifest.characters[id] ? manifest.characters[id] : {};
    const characterLikeness = characterRecord.likenessAuthority || {};
    const actualLikenessAuthoritySha256 = fs.existsSync(likenessAuthorityPath)
      ? sha256File(likenessAuthorityPath)
      : null;
    const likenessAuthorityMatches = Boolean(
      likeness.status === 'PASS' &&
      projectLikeness.status === 'CREATOR_APPROVED_V1' &&
      characterLikeness.status === 'LOCKED_TO_APPROVED_ALIGNMENT_V1' &&
      likeness.authorityStatus === projectLikeness.status &&
      likeness.characterAuthorityStatus === characterLikeness.status &&
      likeness.authorityDocument === projectLikeness.document &&
      actualLikenessAuthoritySha256 &&
      typeof likeness.authorityDocumentSha256 === 'string' &&
      /^[0-9a-f]{64}$/i.test(likeness.authorityDocumentSha256) &&
      likeness.authorityDocumentSha256.toLowerCase() === actualLikenessAuthoritySha256 &&
      typeof projectLikeness.referenceSha256 === 'string' &&
      /^[0-9a-f]{64}$/i.test(projectLikeness.referenceSha256) &&
      typeof likeness.approvedReferenceSha256 === 'string' &&
      likeness.approvedReferenceSha256.toLowerCase() === projectLikeness.referenceSha256.toLowerCase()
    );
    const assetSha256 = receipt.assetSha256 || {};
    const hashesMatch = ACTION_NAMES.every(action => {
      const actual = stripHashes && stripHashes[action];
      const recorded = assetSha256[action];
      return typeof actual === 'string' &&
        /^[0-9a-f]{64}$/i.test(actual) &&
        typeof recorded === 'string' &&
        /^[0-9a-f]{64}$/i.test(recorded) &&
        actual.toLowerCase() === recorded.toLowerCase();
    });
    const admissionTransition = admissionTransitionMatches(runtime.exactHead);
    const runtimeHeadMatches = admissionTransition.valid;
    const evidenceManifestMatches = Boolean(
      actualEvidenceManifestSha256 &&
      typeof runtime.evidenceManifestSha256 === 'string' &&
      /^[0-9a-f]{64}$/i.test(runtime.evidenceManifestSha256) &&
      runtime.evidenceManifestSha256.toLowerCase() === actualEvidenceManifestSha256
    );
    const valid = Boolean(
      receipt.schema === ADMISSION_SCHEMA &&
      receipt.characterId === id &&
      hashesMatch &&
      likenessAuthorityMatches &&
      silhouette.status === 'PASS' &&
      silhouetteEvidenceValid &&
      runtime.status === 'PASS' &&
      runtime.visualSuite === 'PASS' &&
      runtime.browserRouteReplay === 'PASS' &&
      runtime.exactHeadEvidenceCapture === 'PASS' &&
      runtime.visualPerformance === 'PASS' &&
      runtime.beforeAfterCohesion === 'PASS' &&
      runtimeHeadMatches &&
      evidenceManifestMatches
    );
    return {
      path: relativePath.replace(/\\/g, '/'),
      exists: true,
      valid,
      silhouetteStatus: silhouette.status || null,
      participants: rawParticipants.length,
      correctCount: silhouetteCorrect,
      correctRate: silhouetteRate,
      silhouetteEvidenceValid,
      runtimeStatus: runtime.status || null,
      visualSuite: runtime.visualSuite || null,
      browserRouteReplay: runtime.browserRouteReplay || null,
      exactHeadEvidenceCapture: runtime.exactHeadEvidenceCapture || null,
      visualPerformance: runtime.visualPerformance || null,
      beforeAfterCohesion: runtime.beforeAfterCohesion || null,
      evidenceManifestSha256: typeof runtime.evidenceManifestSha256 === 'string' ? runtime.evidenceManifestSha256 : null,
      actualEvidenceManifestSha256,
      evidenceManifestMatches,
      exactHead: typeof runtime.exactHead === 'string' ? runtime.exactHead : null,
      actualHead,
      runtimeHeadMatches,
      admissionTransition,
      hashesMatch,
      likenessStatus: likeness.status || null,
      likenessAuthorityMatches,
      authorityStatus: likeness.authorityStatus || null,
      characterAuthorityStatus: likeness.characterAuthorityStatus || null,
      authorityDocument: likeness.authorityDocument || null,
      authorityDocumentSha256: likeness.authorityDocumentSha256 || null,
      actualLikenessAuthoritySha256,
      approvedReferenceSha256: likeness.approvedReferenceSha256 || null,
      assetSha256: ACTION_NAMES.reduce((out, action) => {
        out[action] = typeof assetSha256[action] === 'string' ? assetSha256[action] : null;
        return out;
      }, {}),
    };
  } catch (error) {
    return { path: relativePath.replace(/\\/g, '/'), exists: true, valid: false, parseError: true };
  }
}

const actualHead = currentGitHead();
const actualEvidenceManifestSha256 = fs.existsSync(evidenceManifestPath) ? sha256File(evidenceManifestPath) : null;

function inspect(id) {
  const record = manifest.characters && manifest.characters[id];
  if (!record) return { id, status: 'MISSING_RECORD', valid: false, strips: [], evidence: inspectAdmissionEvidence(id, {}, actualHead, actualEvidenceManifestSha256) };

  const fieldStrips = record.fieldStrips || {};
  const actionsMatch = sameActions(fieldStrips);
  const strips = ACTION_NAMES.map(action => {
    const spec = fieldStrips[action] || null;
    const expectedFrames = EXPECTED_ACTIONS[action];
    const expectedWidth = FIELD_CELL.width * expectedFrames;
    const contractValid = Boolean(
      spec &&
      spec.frameWidth === FIELD_CELL.width &&
      spec.frameHeight === FIELD_CELL.height &&
      spec.frames === expectedFrames &&
      typeof spec.path === 'string' &&
      spec.path.length > 0
    );
    const file = contractValid ? path.join(root, spec.path) : null;
    const info = file ? pngInfo(file) : { exists: false };
    const sha256 = file && info.exists && info.png ? sha256File(file) : null;
    const transparentCapable = Boolean(info.png && [4, 6].includes(info.colorType));
    const valid = Boolean(
      contractValid &&
      info.exists && info.png &&
      transparentCapable &&
      info.width === expectedWidth &&
      info.height === FIELD_CELL.height
    );
    return {
      action,
      path: spec && spec.path ? spec.path : null,
      expected: [expectedWidth, FIELD_CELL.height],
      expectedFrames,
      manifestContractValid: contractValid,
      actual: info.exists && info.png ? [info.width, info.height] : null,
      transparentCapable,
      sha256,
      valid,
    };
  });

  const complete = actionsMatch && strips.every(s => s.valid);
  const declaredReady = record.status === 'ready' || record.status === 'field-ready';
  const stripHashes = strips.reduce((out, strip) => {
    out[strip.action] = strip.sha256;
    return out;
  }, {});
  const evidence = inspectAdmissionEvidence(id, stripHashes, actualHead, actualEvidenceManifestSha256);
  return { id, manifestStatus: record.status, actionsMatch, complete, declaredReady, evidence, strips };
}

const results = targets.map(inspect);
for (const result of results) console.log(JSON.stringify(result));

const invalidDeclaredReady = results.some(r => r.declaredReady && !r.complete);
const unmetComplete = requireComplete && results.some(r => !r.complete);
const unmetReady = requireReady && results.some(r => !r.declaredReady || !r.complete);
const unmetEvidence = requireEvidence && results.some(r => !r.evidence || !r.evidence.valid);
if (invalidDeclaredReady || unmetComplete || unmetReady || unmetEvidence) {
  console.error('AETHERWAKE_FIELD_PACK_READINESS=BLOCKED');
  process.exit(1);
}

const allComplete = results.every(r => r.complete);
const allReady = results.every(r => r.declaredReady && r.complete);
const state = allReady ? 'READY' : (allComplete ? 'COMPLETE_NOT_PROMOTED' : 'NOT_READY');
console.log('AETHERWAKE_FIELD_PACK_READINESS=' + state);
process.exit(0);
