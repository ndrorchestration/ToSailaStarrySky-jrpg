'use strict';
const assert=require('assert'),fs=require('fs'),vm=require('vm'),path=require('path');
const src=fs.readFileSync(path.join(__dirname,'../modules/authored-character-art.js'),'utf8');
function boot(search){
 const requested=[],pending=[],draws=[];
 const ctx={window:{location:{search}},CORNER:0,push(){},pop(){},noSmooth(){},imageMode(){},
 loadImage(url,good){requested.push(url);pending.push(()=>good({width:384,height:96}));return null;},
 image(...args){draws.push(args);}};
 vm.createContext(ctx);vm.runInContext(src,ctx);
 return {api:ctx.window.AetherAuthoredCharacterArt,requested,draws,flush(){pending.splice(0).forEach(f=>f());}};
}
let t=boot('');
assert.strictEqual(t.api.drawProvisionalFieldCharacter('ionia',120,210,{action:'walk',frame:2}),false);
assert(!t.requested.some(x=>x.includes('ionia-walk-6frame-review')));
t=boot('?candidateFieldArt=1');
t.api.drawProvisionalFieldCharacter('ionia',120,210,{action:'walk',frame:2});
assert(!t.requested.some(x=>x.includes('ionia-walk-6frame-review')));
t=boot('?ioniaReviewArt=1');
t.api.drawProvisionalFieldCharacter('ionia',120,210,{action:'walk',frame:2});
assert(!t.requested.some(x=>x.includes('ionia-walk-6frame-review')));
t=boot('?candidateFieldArt=1&ioniaReviewArt=1');
assert.strictEqual(t.api.isFieldReady('ionia'),false);
assert.strictEqual(t.api.drawProvisionalFieldCharacter('ionia',120,210,{action:'walk',frame:2}),false);
assert(t.requested.includes('art-staging/field/ionia/review/ionia-walk-6frame-review.png'));
t.flush();
assert.strictEqual(t.api.drawProvisionalFieldCharacter('ionia',120,210,{action:'walk',frame:2}),true);
assert.strictEqual(t.draws.length,1);
assert.strictEqual(t.api.isFieldReady('ionia'),false);
// The idle candidate is a single static first pose, not a multi-frame idle pack.
t=boot('?candidateFieldArt=1&ioniaReviewArt=1');
t.api.drawProvisionalFieldCharacter('ionia',120,210,{action:'idle'});
assert(t.requested.some(x=>x.includes('ionia-walk-6frame-review')));
t.flush();
assert.strictEqual(t.api.drawProvisionalFieldCharacter('ionia',120,210,{action:'idle',frame:7}),true);
t=boot('?candidateFieldArt=1&ioniaReviewArt=1');
t.api.drawProvisionalFieldCharacter('ionia',120,210,{action:'attack'});
assert(!t.requested.some(x=>x.includes('ionia-walk-6frame-review')));
console.log('Ionia artwork opt-in preview and safe fallback: PASS');