/* Aetherwake authored character art runtime bridge. */
(function(root){
  'use strict';
  const VERSION='0.3.0';
  const CELL=256;
  const FIELD_CELL_W=64;
  const FIELD_CELL_H=96;
  const EXPRESSION_ORDER=Object.freeze(['neutral','talk','concern','focus','hurt','smile']);
  const PACKS=Object.freeze({
    ionia:Object.freeze({status:'portrait-ready',portraitAtlas:'assets/characters/v1/ionia/portrait-atlas.png',width:768,height:512})
  });
  const FIELD_PACKS=Object.freeze({
    ender:Object.freeze({status:'planned',base:'assets/characters/v1/ender'}),
    ionia:Object.freeze({status:'planned',base:'assets/characters/v1/ionia'})
  });
  const FIELD_FRAMES=Object.freeze({idle:8,walk:6,talk:4,focus:6,attack:8});
  const CANDIDATE_FIELD=Object.freeze({
    ender:Object.freeze({path:'assets/characters/v1/ender/field-idle-walk-candidate.png',width:56,height:36,cellW:28,cellH:36}),
    ionia:Object.freeze({path:'assets/characters/v1/ionia/field-idle-walk-candidate.png',width:56,height:36,cellW:28,cellH:36})
  });
  const state=Object.create(null);
  const fieldState=Object.create(null);
  const candidateState=Object.create(null);
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
  function fieldAction(action){
    const v=String(action||'idle').toLowerCase();
    if(v==='run') return 'walk';
    if(v==='speaking') return 'talk';
    if(v==='focused') return 'focus';
    return Object.prototype.hasOwnProperty.call(FIELD_FRAMES,v)?v:'idle';
  }
  function ensureFieldStrip(id,action){
    const pack=FIELD_PACKS[id];
    if(!pack||pack.status!=='ready'||typeof loadImage!=='function') return null;
    const key=id+':'+action;
    if(!fieldState[key]) fieldState[key]={requested:false,ready:false,failed:false,image:null};
    const entry=fieldState[key];
    if(!entry.requested){
      entry.requested=true;
      const expectedW=FIELD_CELL_W*FIELD_FRAMES[action];
      const path=pack.base+'/field-'+action+'.png';
      try{
        entry.image=loadImage(path,
          img=>{entry.image=img;entry.ready=Boolean(img&&img.width===expectedW&&img.height===FIELD_CELL_H);entry.failed=!entry.ready;},
          ()=>{entry.failed=true;entry.ready=false;entry.image=null;});
      }catch(error){entry.failed=true;entry.ready=false;entry.image=null;}
    }
    return entry;
  }
  function drawFieldCharacter(id,x,y,options={}){
    const pack=FIELD_PACKS[id];
    if(!pack||pack.status!=='ready'||typeof image!=='function') return false;
    const action=fieldAction(options.action || (options.speed>0?'walk':'idle'));
    const entry=ensureFieldStrip(id,action);
    if(!entry||!entry.ready||!entry.image) return false;
    const count=FIELD_FRAMES[action];
    const frame=Math.abs(Math.floor(Number(options.frame)||0))%count;
    const scale=Math.max(0.25,Number(options.scale)||1);
    const dw=FIELD_CELL_W*scale, dh=FIELD_CELL_H*scale;
    const dx=options.anchor==='top-left'?x:x-dw/2;
    const dy=options.anchor==='top-left'?y:y-dh;
    push();
    imageMode(CORNER);
    noSmooth();
    image(entry.image,dx,dy,dw,dh,frame*FIELD_CELL_W,0,FIELD_CELL_W,FIELD_CELL_H);
    pop();
    return true;
  }
  function candidateReviewEnabled(){
    try{
      return Boolean(root && root.location && /(?:\?|&)candidateFieldArt=1(?:&|$)/.test(String(root.location.search||'')));
    }catch(error){return false;}
  }
  function ensureCandidateField(id){
    const spec=CANDIDATE_FIELD[id];
    if(!spec||!candidateReviewEnabled()||typeof loadImage!=='function') return null;
    if(!candidateState[id]) candidateState[id]={requested:false,ready:false,failed:false,image:null};
    const entry=candidateState[id];
    if(!entry.requested){
      entry.requested=true;
      try{
        entry.image=loadImage(spec.path,
          img=>{entry.image=img;entry.ready=Boolean(img&&img.width===spec.width&&img.height===spec.height);entry.failed=!entry.ready;},
          ()=>{entry.failed=true;entry.ready=false;entry.image=null;});
      }catch(error){entry.failed=true;entry.ready=false;entry.image=null;}
    }
    return entry;
  }
  function drawCandidateFieldCharacter(id,x,y,options={}){
    const spec=CANDIDATE_FIELD[id];
    const entry=ensureCandidateField(id);
    if(!spec||!entry||!entry.ready||!entry.image||typeof image!=='function') return false;
    const action=fieldAction(options.action || (options.speed>0?'walk':'idle'));
    const moving=action==='walk';
    const frame=moving ? Math.abs(Math.floor(Number(options.frame)||0))%2 : 0;
    const scale=Math.max(1,Number(options.scale)||2);
    const dw=spec.cellW*scale, dh=spec.cellH*scale;
    const dx=options.anchor==='top-left'?x:x-dw/2;
    const dy=options.anchor==='top-left'?y:y-dh;
    push(); imageMode(CORNER); noSmooth();
    image(entry.image,dx,dy,dw,dh,frame*spec.cellW,0,spec.cellW,spec.cellH);
    pop();
    return true;
  }
  function isFieldReady(id){const pack=FIELD_PACKS[id];return Boolean(pack&&pack.status==='ready');}
  function isPortraitReady(id){const pack=PACKS[id];return Boolean(pack&&pack.status==='portrait-ready');}
  root.AetherAuthoredCharacterArt=Object.freeze({VERSION,PACKS,FIELD_PACKS,FIELD_FRAMES,CANDIDATE_FIELD,EXPRESSION_ORDER,normalizeExpression,drawPortrait,isPortraitReady,drawFieldCharacter,isFieldReady,candidateReviewEnabled,drawCandidateFieldCharacter});
})(typeof window!=='undefined'?window:globalThis);
