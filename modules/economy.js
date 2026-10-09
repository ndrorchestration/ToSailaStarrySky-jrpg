/* ============================================================
   Aetherwake — Economy & Regular Loot Foundation v0.1
   Gold is money. Scrap is salvage/crafting material.
   ============================================================ */
(function(root,factory){
  'use strict';
  const api=factory();
  if(typeof module==='object'&&module.exports) module.exports=api;
  if(root) root.AetherEconomy=api;
})(typeof window!=='undefined'?window:(typeof globalThis!=='undefined'?globalThis:null),function(){
  'use strict';

  const VERSION='0.1.0';

  const ITEMS=Object.freeze({
    'CON-A1-001':Object.freeze({
      id:'CON-A1-001',name:'Field Tonic',kind:'consumable',rarity:'common',
      sellable:true,sellValue:6,unique:false,provenance:false,story:false
    }),
    'CON-A1-002':Object.freeze({
      id:'CON-A1-002',name:'Clearwater Salve',kind:'consumable',rarity:'common',
      sellable:true,sellValue:5,unique:false,provenance:false,story:false
    }),
    'MAT-A1-COMMON-SCRAP':Object.freeze({
      id:'MAT-A1-COMMON-SCRAP',name:'Usable Scrap',kind:'material',rarity:'common',
      sellable:true,sellValue:3,unique:false,provenance:false,story:false
    }),
    'TRD-A1-001':Object.freeze({
      id:'TRD-A1-001',name:'Dock Trade Token',kind:'trade_good',rarity:'common',
      sellable:true,sellValue:10,unique:false,provenance:false,story:false
    }),
    'WPN-A1-COMMON-STAFF':Object.freeze({
      id:'WPN-A1-COMMON-STAFF',name:'Workshop Staff',kind:'weapon',rarity:'uncommon',
      sellable:true,sellValue:18,unique:false,provenance:false,story:false
    }),
    'ARM-A1-COMMON-COAT':Object.freeze({
      id:'ARM-A1-COMMON-COAT',name:'Dockworker Coat',kind:'armor',rarity:'uncommon',
      sellable:true,sellValue:16,unique:false,provenance:false,story:false
    }),
    'REL-UNIQUE-PROOF':Object.freeze({
      id:'REL-UNIQUE-PROOF',name:'Protected Provenance Example',kind:'relic',rarity:'unique',
      sellable:false,sellValue:0,unique:true,provenance:true,story:false
    })
  });

  const LOOT_TABLES=Object.freeze({
    'LOOT-A1-ROUTINE':Object.freeze({
      id:'LOOT-A1-ROUTINE',
      gold:Object.freeze({min:6,max:14}),
      entries:Object.freeze([
        Object.freeze({itemId:'MAT-A1-COMMON-SCRAP',weight:40,min:1,max:2}),
        Object.freeze({itemId:'CON-A1-001',weight:25,min:1,max:1}),
        Object.freeze({itemId:'CON-A1-002',weight:15,min:1,max:1}),
        Object.freeze({itemId:'TRD-A1-001',weight:12,min:1,max:1}),
        Object.freeze({itemId:'WPN-A1-COMMON-STAFF',weight:4,min:1,max:1}),
        Object.freeze({itemId:'ARM-A1-COMMON-COAT',weight:4,min:1,max:1})
      ])
    })
  });

  function clampUnit(v){
    if(!Number.isFinite(v)) return 0;
    if(v<0) return 0;
    if(v>=1) return 0.999999999;
    return v;
  }

  function rollInt(min,max,rng){
    const r=clampUnit(rng());
    return min+Math.floor(r*(max-min+1));
  }

  function pickWeighted(entries,rng){
    const total=entries.reduce((sum,e)=>sum+e.weight,0);
    let cursor=clampUnit(rng())*total;
    for(const e of entries){
      cursor-=e.weight;
      if(cursor<0) return e;
    }
    return entries[entries.length-1];
  }

  function resolveLoot(tableId,rng){
    const table=LOOT_TABLES[tableId];
    if(!table) throw new Error('LOOT_TABLE_UNKNOWN:'+tableId);
    const random=typeof rng==='function'?rng:Math.random;
    const gold=rollInt(table.gold.min,table.gold.max,random);
    const entry=pickWeighted(table.entries,random);
    const quantity=rollInt(entry.min,entry.max,random);
    return Object.freeze({
      tableId,
      gold,
      items:Object.freeze([Object.freeze({itemId:entry.itemId,quantity})])
    });
  }

  function resolveEncounterRewards(encounterClass,rng){
    if(encounterClass!=='routine') throw new Error('ENCOUNTER_REWARD_CLASS_UNKNOWN:'+encounterClass);
    return resolveLoot('LOOT-A1-ROUTINE',rng);
  }

  function canSell(itemId){
    const item=ITEMS[itemId];
    if(!item) return false;
    return item.sellable===true && item.unique!==true && item.provenance!==true && item.story!==true;
  }

  function spendGold(wallet,amount){
    if(!wallet||!Number.isFinite(wallet.gold)) throw new Error('GOLD_WALLET_REQUIRED');
    if(!Number.isInteger(amount)||amount<0) throw new Error('GOLD_AMOUNT_INVALID');
    if(wallet.gold<amount) return false;
    wallet.gold-=amount;
    return true;
  }

  function addGold(wallet,amount){
    if(!wallet||!Number.isFinite(wallet.gold)) throw new Error('GOLD_WALLET_REQUIRED');
    if(!Number.isInteger(amount)||amount<0) throw new Error('GOLD_AMOUNT_INVALID');
    wallet.gold+=amount;
    return wallet.gold;
  }

  function validate(){
    const ids=new Set();
    for(const [id,item] of Object.entries(ITEMS)){
      if(item.id!==id) throw new Error('ECONOMY_ITEM_ID_MISMATCH:'+id);
      if(ids.has(id)) throw new Error('ECONOMY_ITEM_DUPLICATE:'+id);
      ids.add(id);
      if(item.sellable && (!Number.isInteger(item.sellValue)||item.sellValue<0))
        throw new Error('ECONOMY_SELL_VALUE_INVALID:'+id);
    }
    for(const [id,table] of Object.entries(LOOT_TABLES)){
      if(table.id!==id) throw new Error('ECONOMY_LOOT_ID_MISMATCH:'+id);
      if(table.gold.min<0||table.gold.max<table.gold.min) throw new Error('ECONOMY_GOLD_RANGE_INVALID:'+id);
      for(const entry of table.entries){
        if(!ITEMS[entry.itemId]) throw new Error('ECONOMY_LOOT_ITEM_UNKNOWN:'+entry.itemId);
        if(entry.weight<=0) throw new Error('ECONOMY_LOOT_WEIGHT_INVALID:'+entry.itemId);
      }
    }
    return true;
  }

  validate();
  return Object.freeze({
    VERSION,ITEMS,LOOT_TABLES,resolveLoot,resolveEncounterRewards,canSell,spendGold,addGold,validate
  });
});
