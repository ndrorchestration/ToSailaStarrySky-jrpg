"use strict";
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const manifestPath = path.join(root, 'visual-evidence', 'manifest.json');
const contractPath = path.join(root, 'docs', 'visual-style-contract.json');
function fail(message) { throw new Error('VISUAL_PERFORMANCE_FAIL: ' + message); }
if (!fs.existsSync(manifestPath)) fail('visual-evidence/manifest.json missing; run npm run capture:visual-evidence first');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const contract = JSON.parse(fs.readFileSync(contractPath, 'utf8'));
const samples = manifest.performanceSamples || [];
if (samples.length < 4) fail('expected at least four representative performance states');
const p95Limit = contract.performance.p95FrameMsHardLimit;
const spikeLimit = contract.performance.singleFrameSpikeHardLimitMs;
for (const sample of samples) {
  if ((sample.sampleWindows || 0) < 3) fail(sample.id + ' requires >=3 timing windows');
  if (sample.windowP95Median > p95Limit) fail(sample.id + ' median p95 ' + sample.windowP95Median + 'ms > ' + p95Limit + 'ms');
  if (sample.frameMsMax > spikeLimit) fail(sample.id + ' max frame ' + sample.frameMsMax + 'ms > ' + spikeLimit + 'ms');
}
console.log('AETHERWAKE_VISUAL_PERFORMANCE=PASS');
for (const sample of samples) {
  console.log(sample.id + ': median-p95=' + sample.windowP95Median + 'ms worst-window-p95=' + sample.windowP95Worst + 'ms max=' + sample.frameMsMax + 'ms');
}
