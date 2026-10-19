'use strict';
const fs=require('fs'),vm=require('vm'),assert=require('assert'),path=require('path');
const src=fs.readFileSync(path.join(__dirname,'../modules/authored-character-art.js'),'utf8');
function run(search) {
 const paths=[],draws=[],queued=[];
 const ctx={window:{location:{search}},CORNER:0,push(){},pop(){},noSmooth(){},imageMode(){},
   loadImage(url,good){paths.push(url);queued.push(()=>good({width:384,height:96}));},
   image(...args){draws.push(args);}};
 vm.createContext(ctx);vm.runInContext(src,ctx);
 const api=ctx.window.AetherAuthoredCharacterArt;
 api.drawAuthoredFieldCandidate('ender',200,200,{action:'walk',frame:1,scale:2});
 queued.forEach(fn=>fn());
 const success=api.drawAuthoredFieldCandidate('ender',200,200,{action:'walk',frame:1,scale:2});
 return {paths,success,draws};
}
let r=run('');
assert.deepStrictEqual(r.paths,[]);
r=run('?enderReviewResample=lanczos');
assert.deepStrictEqual(r.paths,[]);
for(const opt of ['lanczos','bicubic']){
 r=run('?candidateFieldArt=1&enderReviewResample='+opt);
 assert.strictEqual(r.success,true);
 assert.deepStrictEqual(r.paths,['art-staging/field/ender/review-alt/field-walk-'+opt+'.png']);
 assert.strictEqual(r.draws.length,1);
}
r=run('?candidateFieldArt=1&enderReviewResample=unrecognized');
assert.deepStrictEqual(r.paths,['art-staging/field/ender/candidate/field-walk.png']);
r=run('?candidateFieldArt=1');
assert.deepStrictEqual(r.paths,['art-staging/field/ender/candidate/field-walk.png']);
console.log('Ender resampling review opt-in/fallback: PASS');
