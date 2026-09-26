/* eslint-env node */
'use strict';
const fs=require('fs'),path=require('path'),vm=require('vm');
const root=path.resolve(__dirname,'..');
const source=fs.readFileSync(path.join(root,'modules','authored-character-art.js'),'utf8');
const sandbox={window:{},globalThis:{}}; vm.createContext(sandbox); vm.runInContext(source,sandbox);
const api=sandbox.window.AetherAuthoredCharacterArt;
if(!api) throw new Error('authored character art API missing');
if(api.VERSION!=='0.1.0') throw new Error('version drift');
if(!api.isPortraitReady('ionia')) throw new Error('Ionia portrait pack must be admitted');
if(api.isPortraitReady('ender')) throw new Error('Ender portrait must remain unadmitted');
if(api.EXPRESSION_ORDER.join(',')!=='neutral,talk,concern,focus,hurt,smile') throw new Error('expression order drift');
if(api.normalizeExpression('speaking')!=='talk') throw new Error('speaking alias drift');
if(api.normalizeExpression('nonsense')!=='neutral') throw new Error('unknown expressions must fail to neutral');
if(!source.includes("return false;")) throw new Error('fail-safe fallback contract missing');
console.log('Aetherwake authored character art runtime bridge: PASS');
