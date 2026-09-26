/* Aetherwake opt-in character art candidate preview. */
(function(root){
  'use strict';
  const PARAM='aetherwakeArtPreview';
  const PATHS=Object.freeze({
    aepex:'assets/characters/v1/aepex/portrait-atlas-candidate.png',
    reson:'assets/characters/v1/reson/portrait-atlas-candidate.png',
    ender:'assets/characters/v1/ender/portrait-atlas-candidate.png'
  });
  const CELL=256,WIDTH=768,HEIGHT=512;
  const ORDER=Object.freeze(['neutral','talk','concern','focus','hurt','smile']);
  const search=root.location&&root.location.search?root.location.search:'';
  let requested=null;
  try{requested=new URLSearchParams(search).get(PARAM);}catch(error){requested=null;}
  const states={};
  function getPreviewCharacterId(){return Object.prototype.hasOwnProperty.call(PATHS,requested)?requested:null;}
  function normalizeExpression(expression){
    const value=String(expression||'neutral').toLowerCase();
    if(ORDER.includes(value))return value;
    if(value==='speaking')return 'talk';
    if(value==='worried')return 'concern';
    if(value==='focused')return 'focus';
    if(value==='injured')return 'hurt';
    if(value==='happy')return 'smile';
    return 'neutral';
  }
  function ensureLoaded(id){
    if(id!==getPreviewCharacterId()||typeof loadImage!=='function')return false;
    const state=states[id]||(states[id]={requested:false,ready:false,failed:false,image:null});
    if(!state.requested){
      state.requested=true;
      try{
        state.image=loadImage(PATHS[id],
          image=>{state.image=image;state.ready=Boolean(image&&image.width===WIDTH&&image.height===HEIGHT);state.failed=!state.ready;},
          ()=>{state.failed=true;state.ready=false;state.image=null;});
      }catch(error){state.failed=true;state.ready=false;state.image=null;}
    }
    return state.ready;
  }
  function drawPortrait(id,x,y,size,options){
    if(id!==getPreviewCharacterId()||!ensureLoaded(id)||typeof image!=='function')return false;
    const state=states[id],index=ORDER.indexOf(normalizeExpression(options&&options.expression));
    push();imageMode(CORNER);image(state.image,x,y,size,size,(index%3)*CELL,Math.floor(index/3)*CELL,CELL,CELL);pop();
    return true;
  }
  root.AetherCharacterArtPreview=Object.freeze({PARAM,CHARACTERS:Object.freeze(Object.keys(PATHS)),PATHS,CELL,WIDTH,HEIGHT,ORDER,getPreviewCharacterId,normalizeExpression,drawPortrait});
})(typeof window!=='undefined'?window:globalThis);
