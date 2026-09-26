/* Aetherwake opt-in character art candidate preview. */
(function(root){
  'use strict';
  const PARAM='aetherwakeArtPreview';
  const CHARACTER='aepex';
  const PATH='assets/characters/v1/aepex/portrait-atlas-candidate.png';
  const CELL=256;
  const WIDTH=768;
  const HEIGHT=512;
  const ORDER=Object.freeze(['neutral','talk','concern','focus','hurt','smile']);
  const search=root.location&&root.location.search?root.location.search:'';
  let requested=null;
  try{requested=new URLSearchParams(search).get(PARAM);}catch(error){requested=null;}
  const state={requested:false,ready:false,failed:false,image:null};
  function getPreviewCharacterId(){return requested===CHARACTER?CHARACTER:null;}
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
  function ensureLoaded(){
    if(!getPreviewCharacterId()||typeof loadImage!=='function')return false;
    if(!state.requested){
      state.requested=true;
      try{
        state.image=loadImage(PATH,
          image=>{state.image=image;state.ready=Boolean(image&&image.width===WIDTH&&image.height===HEIGHT);state.failed=!state.ready;},
          ()=>{state.failed=true;state.ready=false;state.image=null;});
      }catch(error){state.failed=true;state.ready=false;state.image=null;}
    }
    return state.ready;
  }
  function drawPortrait(id,x,y,size,options){
    if(id!==CHARACTER||!getPreviewCharacterId()||!ensureLoaded()||typeof image!=='function')return false;
    const expression=normalizeExpression(options&&options.expression);
    const index=ORDER.indexOf(expression);
    const sx=(index%3)*CELL;
    const sy=Math.floor(index/3)*CELL;
    push();
    imageMode(CORNER);
    image(state.image,x,y,size,size,sx,sy,CELL,CELL);
    pop();
    return true;
  }
  root.AetherCharacterArtPreview=Object.freeze({
    PARAM,CHARACTER,PATH,CELL,WIDTH,HEIGHT,ORDER,
    getPreviewCharacterId,normalizeExpression,drawPortrait
  });
})(typeof window!=='undefined'?window:globalThis);
