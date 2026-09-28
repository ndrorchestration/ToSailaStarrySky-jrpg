/* ============================================================
   Aetherwake JRPG — Character Canon / Art Contract
   modules/character-canon.js

   Authority boundary:
   - Identity facts and constraints reflect the canonical Notion dossiers.
   - visualInterpretation lists allowed art-direction guidance, not immutable canon.
   - openVisualDecisions must not be silently promoted into canon.
   ============================================================ */
(function(root,factory){
  'use strict';
  const api=factory();
  if(typeof module==='object'&&module.exports) module.exports=api;
  if(root) root.AetherCharacterCanon=api;
})(typeof window!=='undefined'?window:(typeof globalThis!=='undefined'?globalThis:null),function(){
  'use strict';

  const VERSION='0.3.0';
  const SOURCE='Notion canonical character dossiers';

  function freeze(value){
    if(!value||typeof value!=='object'||Object.isFrozen(value)) return value;
    Object.freeze(value);
    Object.keys(value).forEach(k=>freeze(value[k]));
    return value;
  }

  const SHARED_OPEN_VISUAL_DECISIONS=Object.freeze([
    'hairColor','eyeColor','ethnicity','exactCostume'
  ]);

  const PROFILES=freeze({
    ender:{
      id:'ender',name:'Ender',age:22,nativeJob:'Rift Scholar',
      canon:{
        build:'slender-to-average; explicitly not especially brawny',
        disposition:['anxious','idealistic','intellectually oriented'],
        wakeStatus:'relatively new aboard the Aureate Wake',
        equipmentAuthority:{
          mainWeapon:'staff',
          secondaryWeapon:'OPEN',
          magicRequiresWeapon:false,
        },
      },
      art:{
        silhouette:'compact scholar-traveler rather than generic battle mage',
        appearance:{
          hair:'very short dark copper-brown / auburn buzz cut',
          eyes:'bright green',
          face:'lean youthful adult face with light freckles',
          goggles:'worn brass/bronze goggles with green lenses across the forehead',
          costumeLanguage:'creator-approved natural-tone field-scholar treatment; olive/green and tan/cream practical layers',
        },
        motifs:['study','spatial/aetheric pattern work','practical shipboard life','resonator-staff or scholarly instrumentation'],
        avoid:['bodybuilder proportions','generic wizard robes','generic battle-mage presentation','dark medium-length/tousled hair','hazel/light-brown eye substitution'],
      },
      openVisualDecisions:['ethnicity','exactCostume','secondaryWeapon'],
    },
    lyra:{
      id:'lyra',name:'Lyra',age:24,nativeJob:null,
      canon:{
        role:'frequency/dream-sensitive receiver',
        training:'comparatively untrained; perceives before she can necessarily formalize',
        family:'single mother of Talen, age 5',
        equipmentAuthority:{
          mainWeapon:'chakram',
          secondaryWeapon:'OPEN',
          magicRequiresWeapon:false,
        },
      },
      art:{
        silhouette:'adult, grounded, perceptive receiver',
        motifs:['listening','resonance','dreams','subtle frequency phenomena'],
        avoid:['childlike presentation','green nature mage','forest priestess'],
      },
      openVisualDecisions:SHARED_OPEN_VISUAL_DECISIONS.concat(['finalClass','secondaryWeapon']),
    },
    ionia:{
      id:'ionia',name:'Ionia',age:28,nativeJob:null,
      canon:{
        role:'captain and owner of the Aureate Wake',
        relationship:'Lyra\'s cousin and strong caretaker presence',
        experience:'served Captain Denith for 10 years',
        expertise:['navigation','sky-lanes','Core knowledge'],
        spellcastingIdentity:'not established',
        equipmentAuthority:{
          mainWeapon:'mace',
          secondaryWeapon:'OPEN',
          magicRequiresWeapon:false,
        },
      },
      art:{
        silhouette:'experienced young-adult captain/navigator with command posture',
        motifs:['sky-navigation gear','weathered expedition clothing','Wake-specific instruments'],
        avoid:['elderly presentation','farmer archetype','invented spellcaster identity'],
      },
      openVisualDecisions:SHARED_OPEN_VISUAL_DECISIONS.concat(['secondaryWeapon','finalClass']),
    },
    reson:{
      id:'reson',name:'Reson',age:25,nativeJob:null,
      canon:{
        role:'young burly Weapon Master',
        background:'former military service after paramilitary family upbringing',
        durability:'very high',
        temperament:['gruff','heart of gold','wise beyond his years','still recognizably young'],
        weapons:['combat-rifle-type firearm','pike','sword'],
        equipmentAuthority:{
          mainWeapon:'sword',
          secondaryWeapon:'assault-style rifle',
          magicRequiresWeapon:false,
          note:'pike remains historical/weapon-vocabulary canon but is not selected as the starting main or secondary weapon',
        },
      },
      art:{
        silhouette:'broadest and heaviest-built protagonist; visibly martial',
        motifs:['disciplined equipment','rifle','pike/sword vocabulary','former-service practicality'],
        avoid:['frail build','magic-first silhouette','invented faction insignia'],
      },
      openVisualDecisions:SHARED_OPEN_VISUAL_DECISIONS.concat(['exactFormerServiceInsignia']),
    },
    aepex:{
      id:'aepex',name:'Aepex',age:27,nativeJob:null,
      canon:{
        role:'inventor / machinery specialist / tech-head',
        temperament:['brainy','confident','chill','cool under pressure'],
        education:'formally educated plus self-taught curiosity',
        interests:['computers','technology','mechanics','invention'],
        equipmentAuthority:{
          mainWeapon:'martial arts',
          secondaryWeapon:'OPEN',
          magicRequiresWeapon:false,
        },
      },
      art:{
        silhouette:'relaxed systems specialist / field engineer',
        motifs:['solarpunk engineering','diagnostics','computation/interfaces','tools','configurable gizmos','brass/rootwood/aether-tech materials'],
        avoid:['generic wizard imagery','magic-staff default','pure mechanic-without-computation presentation'],
      },
      openVisualDecisions:SHARED_OPEN_VISUAL_DECISIONS.concat(['secondaryWeapon','finalClass']),
    },
  });

  function get(id){ return PROFILES[id]||null; }
  function validate(){
    const ids=['ender','lyra','ionia','reson','aepex'];
    if(Object.keys(PROFILES).join('|')!==ids.join('|')) throw new Error('CHARACTER_CANON_ORDER_INVALID');
    for(const id of ids){
      const p=PROFILES[id];
      if(!p||p.id!==id||!p.name||!Number.isInteger(p.age)) throw new Error('CHARACTER_CANON_PROFILE_INVALID:'+id);
      if(!p.art||!Array.isArray(p.art.motifs)||!Array.isArray(p.art.avoid)) throw new Error('CHARACTER_ART_CONTRACT_INVALID:'+id);
      if(!Array.isArray(p.openVisualDecisions)) throw new Error('CHARACTER_OPEN_DECISIONS_INVALID:'+id);
    }
    return true;
  }
  validate();
  return Object.freeze({VERSION,SOURCE,PROFILES,get,validate});
});
