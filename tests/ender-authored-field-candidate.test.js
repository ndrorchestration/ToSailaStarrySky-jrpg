'use strict';
const assert=require('assert'),fs=require('fs'),vm=require('vm'),path=require('path');
const source=fs.readFileSync(path.join(__dirname,'../modules/authored-character-art.js'),'utf8');
function boot(search='',bad=false) {
 const requests=[],draws=[],pending=[];
 const s={window:{location:{search}},globalThis:{},CORNER:0,push(){},pop(){},noSmooth(){},imageMode(){},
 loadImage(url,ok,fail){requests.push(url); const action=(url.match(/field-(\w+)\.png/)||[])[1]; const counts={idle:8,walk:6,talk:4,focus:6,attack:8}; const img={width:bad?1:64*counts[action],height:96}; pending.push(()=>ok(img));return img;},
 image(...args){draws.push(args);}};
 vm.createContext(s);vm.runInContext(source,s);
 return {api:s.window.AetherAuthoredCharacterArt,requests,draws,flush(){pending.splice(0).forEach(f=>f());}};
}
let t=boot();assert.strictEqual(t.api.drawAuthoredFieldCandidate('ender',100,100),false);assert.deepStrictEqual(t.requests,[]);
t=boot('?candidateFieldArt=1');
assert.strictEqual(t.api.isFieldReady('ender'),false);
assert.strictEqual(t.api.drawAuthoredFieldCandidate('ionia',100,100),false);assert.deepStrictEqual(t.requests,[]);
for(const [action,count] of Object.entries({idle:8,walk:6,talk:4,focus:6,attack:8})){
 assert.strictEqual(t.api.drawAuthoredFieldCandidate('ender',100,200,{action,frame:count+1,scale:2}),false);t.flush();
 assert.strictEqual(t.api.drawAuthoredFieldCandidate('ender',100,200,{action,frame:count+1,scale:2}),true);
 const draw=t.draws.at(-1);assert.deepStrictEqual(draw.slice(1),[68,104,64,96,64,0,64,96]);
}
assert.strictEqual(new Set(t.requests).size,5);assert(t.requests.every(p=>p.startsWith('art-staging/field/ender/candidate/')));
t=boot('?candidateFieldArt=1',true);t.api.drawAuthoredFieldCandidate('ender',0,0);t.flush();assert.strictEqual(t.api.drawAuthoredFieldCandidate('ender',0,0),false);assert.strictEqual(t.draws.length,0);
console.log('Ender authored field candidate: PASS (opt-in, five actions, frame wrap, geometry reject, readiness unchanged)');

