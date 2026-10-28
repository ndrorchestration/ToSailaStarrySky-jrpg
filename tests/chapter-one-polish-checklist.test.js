'use strict';

// This is document-schema QA, NOT a gameplay or art acceptance test.
// No test in this file is permission to check a real release checklist box.
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const assert = require('node:assert/strict');

const DOC = fs.readFileSync(path.join(__dirname,
  '../docs/CHAPTER_ONE_HIGH_QUALITY_POLISH_CHECKLIST_2026-10-28.md'), 'utf8');
const lines = DOC.split(/\r?\n/);
const items = lines.filter(line => /^- \[[ xX]\] \*\*CH1-\d{2}\*\*/.test(line));
const parsed = items.map(line => {
  const match = line.match(/^- \[([ xX])\] \*\*CH1-(\d{2})\*\* \[(P[012]) \| ([^\]]+)\] \*\*([^*]+)\*\*\. Acceptance: (.+) Evidence required: (.+)$/);
  assert.ok(match, 'checklist row must include stable ID, P priority, discipline, title, acceptance, and evidence');
  return {checked: match[1] !== ' ', number: Number(match[2]), priority:match[3],
    discipline:match[4], title:match[5], acceptance:match[6], evidence:match[7]};
});

test('32 numbered, unique, unclosed high-quality gates; no accidental PASS labels', () => {
  assert.equal(parsed.length,32);
  assert.deepEqual(parsed.map(item=>item.number),Array.from({length:32},(_,i)=>i+1));
  assert.ok(parsed.every(item=>!item.checked),'no acceptance item can be marked passed from draft evidence');
  assert.deepEqual(parsed.reduce((out,item)=>(out[item.priority]=(out[item.priority]||0)+1,out),{}),
    {P0:15,P1:11,P2:6});
});

test('every item states measurable acceptance and evidence ownership', () => {
  for(const item of parsed){
    assert.ok(item.title.length>=9,'descriptive gate');
    assert.ok(item.discipline.length>=3,'named discipline');
    assert.ok(item.acceptance.length>=90,'acceptance is not a vague slogan CH1-'+item.number);
    assert.ok(item.evidence.length>=40,'requires specific proof CH1-'+item.number);
  }
  assert.match(DOC,/Creator-approved publishable Chapter One preview/);
  assert.match(DOC,/exact final source\+installer SHA/);
});

test('required creator narrative order and fail-closed gameplay controls are explicit', () => {
  const required = [
    'Ender', 'Ionia first, Lyra second','Talen','Denith','remembered shanty',
    'failed material-only retest','two independent clues out of three',
    'real local 2D water contact','no true flight or combat unlock',
    'noncombat child','original remembered captain','no audio alone',
    'historical old-runtime acceptance','F8 family','one authoritative chapter route'
  ];
  for(const phrase of required)
    assert.ok(DOC.includes(phrase), 'required high-quality gate missing: '+phrase);
});

test('exact draft receipts remain distinct from production and human approvals', () => {
  for(const id of [425,510,547,548,551]){
    assert.ok(DOC.includes('/pull/'+id),'missing source lineage PR '+id);
  }
  for(const run of [40636277938,40636584446]){
    assert.ok(DOC.includes('/runs/'+run),'missing exact-head native receipt '+run);
  }
  assert.match(DOC,/Chapter One polish acceptance = HOLD/);
  assert.match(DOC,/not a claim that Chapter One is finished/i);
  assert.match(DOC,/Defender-on custody/);
  assert.match(DOC,/HUMAN|human|Human/);
  assert.match(DOC,/The first suggested reversible player-facing patch/);
});

test('P0 blockers do not hide behind optional art or installer proofs',()=>{
  const p0=parsed.filter(i=>i.priority==='P0').map(i=>i.title.toLowerCase()).join(' ');
  for(const word of ['employment','flight','splashdown','lyra','shanty','save','retest',
    'objective','inventory','harmonic'])
    assert.ok(p0.includes(word),'missing essential P0 gate '+word);
});
