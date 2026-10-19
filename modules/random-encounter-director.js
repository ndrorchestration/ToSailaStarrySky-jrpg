/* Review-only encounter pacing; never changes the default authored route. */
(function(root,factory){
 'use strict';
 const api=factory();
 if(typeof module==='object'&&module.exports)module.exports=api;
 if(root)root.AetherRandomEncounterDirector=api;
})(typeof window!=='undefined'?window:null,function(){
 'use strict';
 // A deliberately tiny, auditable area table for the isolated Chapter 1 pilot.
 // Story hazard zones remain exclusively owned by authored quest logic.
 function enemyForTile(tileX,tileY){
   if(!Number.isInteger(tileX)||!Number.isInteger(tileY))
     throw new Error('INVALID_ENCOUNTER_TILE');
   return tileX<14 && tileY>=17 ? 'windShear' : 'aetherLeak';
 }
 function create(options={}){
   const minSteps=Number.isInteger(options.minSteps)?options.minSteps:12;
   const maxSteps=Number.isInteger(options.maxSteps)?options.maxSteps:26;
   const chance=Number.isFinite(options.chance)?options.chance:0.12;
   if(minSteps<1||maxSteps<minSteps||chance<0||chance>1)
     throw new Error('INVALID_ENCOUNTER_PACING');
   let steps=0;
   return Object.freeze({
     onWalk(rng=Math.random){
       steps++;
       if(steps<minSteps)return false;
       const roll=steps>=maxSteps ? true : rng()<chance;
       if(roll){steps=0;return true;}
       return false;
     },
     reset(){steps=0;},
     getSteps(){return steps;},
     restoreSteps(value){
       if(!Number.isInteger(value)||value<0||value>=maxSteps)
         throw new Error('INVALID_ENCOUNTER_STEPS');
       steps=value;
     }
   });
 }
 return Object.freeze({create,enemyForTile});
});
