/* ============================================================
   Aetherwake JRPG — Equipment System Foundation
   modules/equipment-system.js

   Authority boundary:
   - Starting weapon identities are creator-locked.
   - Secondary/ranged weapons remain OPEN except Reson's rifle.
   - Detailed job/class permissions, auto-equip scoring, armor families,
     item stats, and crafting economy are not yet authorized.
   ============================================================ */
(function(root,factory){
  'use strict';
  const api=factory();
  if(typeof module==='object'&&module.exports) module.exports=api;
  if(root) root.AetherEquipmentSystem=api;
})(typeof window!=='undefined'?window:(typeof globalThis!=='undefined'?globalThis:null),function(){
  'use strict';

  const VERSION='0.1.0';
  const STATUS='FOUNDATION_PARTIALLY_LOCKED';

  const WEAPON_FAMILIES=Object.freeze({
    STAFF:'staff',
    SWORD:'sword',
    RIFLE:'rifle',
    MARTIAL_ARTS:'martial-arts',
    MACE:'mace',
    CHAKRAM:'chakram',
  });

  const ITEMS=Object.freeze({
    enderStarterStaff:Object.freeze({
      id:'ender-starter-staff',
      displayName:'Starter Fighting Staff',
      nameStatus:'PROVISIONAL_NAME',
      family:WEAPON_FAMILIES.STAFF,
      slot:'mainWeapon',
      ownerAffinity:'ender',
      acquisition:'starting',
      upgradePath:'PARTY_DEVELOPED_CANDIDATE',
      magicRequirement:false,
      visualAuthority:'docs/ENDER_STARTER_STAFF_PRODUCTION_BRIEF.md',
      statsStatus:'OPEN',
    }),
    resonStarterSword:Object.freeze({
      id:'reson-starter-sword',
      displayName:'Starter Sword',
      nameStatus:'PROVISIONAL_NAME',
      family:WEAPON_FAMILIES.SWORD,
      slot:'mainWeapon',
      ownerAffinity:'reson',
      acquisition:'starting',
      statsStatus:'OPEN',
    }),
    resonStarterRifle:Object.freeze({
      id:'reson-starter-rifle',
      displayName:'Assault-Style Rifle',
      nameStatus:'FAMILY_DESCRIPTION_ONLY',
      family:WEAPON_FAMILIES.RIFLE,
      slot:'secondaryWeapon',
      ownerAffinity:'reson',
      acquisition:'starting',
      statsStatus:'OPEN',
    }),
    aepexMartialArts:Object.freeze({
      id:'aepex-martial-arts',
      displayName:'Martial Arts',
      nameStatus:'COMBAT_STYLE',
      family:WEAPON_FAMILIES.MARTIAL_ARTS,
      slot:'mainWeapon',
      ownerAffinity:'aepex',
      acquisition:'innate',
      statsStatus:'OPEN',
    }),
    ioniaStarterMace:Object.freeze({
      id:'ionia-starter-mace',
      displayName:'Starter Mace',
      nameStatus:'PROVISIONAL_NAME',
      family:WEAPON_FAMILIES.MACE,
      slot:'mainWeapon',
      ownerAffinity:'ionia',
      acquisition:'starting',
      statsStatus:'OPEN',
    }),
    lyraStarterChakram:Object.freeze({
      id:'lyra-starter-chakram',
      displayName:'Starter Chakram',
      nameStatus:'PROVISIONAL_NAME',
      family:WEAPON_FAMILIES.CHAKRAM,
      slot:'mainWeapon',
      ownerAffinity:'lyra',
      acquisition:'starting',
      rangedBehaviorStatus:'OPEN',
      statsStatus:'OPEN',
    }),
  });

  const STARTING_LOADOUTS=Object.freeze({
    ender:Object.freeze({
      mainWeapon:'ender-starter-staff',
      secondaryWeapon:null,
      secondaryStatus:'OPEN',
    }),
    reson:Object.freeze({
      mainWeapon:'reson-starter-sword',
      secondaryWeapon:'reson-starter-rifle',
      secondaryStatus:'LOCKED',
    }),
    aepex:Object.freeze({
      mainWeapon:'aepex-martial-arts',
      secondaryWeapon:null,
      secondaryStatus:'OPEN',
    }),
    ionia:Object.freeze({
      mainWeapon:'ionia-starter-mace',
      secondaryWeapon:null,
      secondaryStatus:'OPEN',
    }),
    lyra:Object.freeze({
      mainWeapon:'lyra-starter-chakram',
      secondaryWeapon:null,
      secondaryStatus:'OPEN',
    }),
  });

  function getItem(id){
    return Object.values(ITEMS).find(item=>item.id===id)||null;
  }

  function getStartingLoadout(characterId){
    const loadout=STARTING_LOADOUTS[characterId];
    if(!loadout) throw new Error('EQUIPMENT_UNKNOWN_CHARACTER:'+characterId);
    return Object.freeze({
      mainWeapon:loadout.mainWeapon,
      secondaryWeapon:loadout.secondaryWeapon,
      secondaryStatus:loadout.secondaryStatus,
    });
  }

  function createEquipmentState(characterId){
    const loadout=getStartingLoadout(characterId);
    return {
      schemaVersion:1,
      characterId,
      mainWeapon:loadout.mainWeapon,
      secondaryWeapon:loadout.secondaryWeapon,
      head:null,
      body:null,
      accessory1:null,
      accessory2:null,
      permissionModelStatus:'OPEN',
      autoEquipStatus:'NOT_AUTHORIZED',
    };
  }

  function canEquip(characterId,itemId,slot){
    const item=getItem(itemId);
    if(!item) return Object.freeze({authorized:false,reason:'UNKNOWN_ITEM'});
    if(!STARTING_LOADOUTS[characterId]) return Object.freeze({authorized:false,reason:'UNKNOWN_CHARACTER'});
    if(slot!==item.slot) return Object.freeze({authorized:false,reason:'SLOT_MISMATCH'});

    // Only creator-locked starting equipment is authorized before the
    // job/class permission matrix exists.
    const starting=STARTING_LOADOUTS[characterId];
    const authorized=(slot==='mainWeapon'&&starting.mainWeapon===itemId)||
      (slot==='secondaryWeapon'&&starting.secondaryWeapon===itemId);

    return Object.freeze({
      authorized,
      reason:authorized?'LOCKED_STARTING_LOADOUT':'JOB_CLASS_PERMISSION_MODEL_OPEN',
    });
  }

  function autoEquip(){
    throw new Error('EQUIPMENT_AUTO_EQUIP_NOT_AUTHORIZED');
  }

  function validate(){
    const ids=['ender','reson','aepex','ionia','lyra'];
    for(const id of ids){
      const loadout=STARTING_LOADOUTS[id];
      if(!loadout) throw new Error('EQUIPMENT_STARTING_LOADOUT_MISSING:'+id);
      const main=getItem(loadout.mainWeapon);
      if(!main||main.slot!=='mainWeapon'||main.ownerAffinity!==id){
        throw new Error('EQUIPMENT_MAIN_WEAPON_INVALID:'+id);
      }
      if(loadout.secondaryWeapon){
        const secondary=getItem(loadout.secondaryWeapon);
        if(!secondary||secondary.slot!=='secondaryWeapon'||secondary.ownerAffinity!==id){
          throw new Error('EQUIPMENT_SECONDARY_WEAPON_INVALID:'+id);
        }
      }
    }
    if(STARTING_LOADOUTS.reson.secondaryWeapon!=='reson-starter-rifle'){
      throw new Error('EQUIPMENT_RESON_RIFLE_AUTHORITY_INVALID');
    }
    for(const id of ['ender','aepex','ionia','lyra']){
      if(STARTING_LOADOUTS[id].secondaryWeapon!==null||STARTING_LOADOUTS[id].secondaryStatus!=='OPEN'){
        throw new Error('EQUIPMENT_OPEN_SECONDARY_PROMOTED:'+id);
      }
    }
    if(ITEMS.enderStarterStaff.magicRequirement!==false){
      throw new Error('EQUIPMENT_ENDER_STAFF_MAGIC_DEPENDENCY_INVALID');
    }
    return true;
  }

  validate();
  return Object.freeze({
    VERSION,STATUS,WEAPON_FAMILIES,ITEMS,STARTING_LOADOUTS,
    getItem,getStartingLoadout,createEquipmentState,canEquip,autoEquip,validate
  });
});
