/* Aetherwake authored character art runtime bridge. */
(function(root){
  'use strict';
  const VERSION='0.1.0';
  const CELL=256;
  const EXPRESSION_ORDER=Object.freeze(['neutral','talk','concern','focus','hurt','smile']);
  const PACKS=Object.freeze({
    ionia:Object.freeze({status:'portrait-ready',portraitAtlas:'assets/characters/v1/ionia/portrait-atlas.png',width:768,height:512})
  });
  const state=Object.create(null);
  function normalizeExpression(expression){
    const v=String(expression||'neutral').toLowerCase();
    if(EXPRESSION_ORDER.includes(v)) return v;
    if(v==='speaking') return 'talk';
    if(v==='worried') return 'concern';
    if(v==='focused') return 'focus';
    if(v==='injured') return 'hurt';
    if(v==='happy') return 'smile';
    return 'neutral';
  }
  function ensurePortraitPack(id){
    const pack=PACKS[id];
    if(!pack||pack.status!=='portrait-ready'||typeof loadImage!=='function') return null;
    if(!state[id]) state[id]={requested:false,ready:false,failed:false,image:null};
    const entry=state[id];
    if(!entry.requested){
      entry.requested=true;
      try{
        entry.image=loadImage(pack.portraitAtlas,
          img=>{entry.image=img;entry.ready=Boolean(img&&img.width===pack.width&&img.height===pack.height);entry.failed=!entry.ready;},
          ()=>{entry.failed=true;entry.ready=false;entry.image=null;});
      }catch(error){entry.failed=true;entry.ready=false;entry.image=null;}
    }
    return entry;
  }
  function drawPortrait(id,x,y,size,options={}){
    const pack=PACKS[id];
    const entry=ensurePortraitPack(id);
    if(!pack||!entry||!entry.ready||!entry.image||typeof image!=='function') return false;
    const expression=normalizeExpression(options.expression);
    const index=Math.max(0,EXPRESSION_ORDER.indexOf(expression));
    const sx=(index%3)*CELL, sy=Math.floor(index/3)*CELL;
    push();
    imageMode(CORNER);
    noSmooth();
    image(entry.image,x,y,size,size,sx,sy,CELL,CELL);
    pop();
    return true;
  }
  function isPortraitReady(id){const pack=PACKS[id];return Boolean(pack&&pack.status==='portrait-ready');}
  root.AetherAuthoredCharacterArt=Object.freeze({VERSION,PACKS,EXPRESSION_ORDER,normalizeExpression,drawPortrait,isPortraitReady});
})(typeof window!=='undefined'?window:globalThis);
