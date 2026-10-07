'use strict';
const assert=require('assert');
const eq=require('../modules/equipment-system.js');

assert.strictEqual(eq.validate(),true);
assert.strictEqual(eq.VERSION,'0.1.0');

assert.strictEqual(eq.getItem('ender-starter-staff').family,'staff');
assert.strictEqual(eq.getItem('ender-starter-staff').magicRequirement,false);
assert.strictEqual(eq.getStartingLoadout('ender').mainWeapon,'ender-starter-staff');
assert.strictEqual(eq.getStartingLoadout('ender').secondaryWeapon,null);

assert.strictEqual(eq.getStartingLoadout('reson').mainWeapon,'reson-starter-sword');
assert.strictEqual(eq.getStartingLoadout('reson').secondaryWeapon,'reson-starter-rifle');

for(const id of ['aepex','ionia','lyra']){
  assert.strictEqual(eq.getStartingLoadout(id).secondaryWeapon,null);
  assert.strictEqual(eq.getStartingLoadout(id).secondaryStatus,'OPEN');
}

assert.strictEqual(eq.canEquip('ender','ender-starter-staff','mainWeapon').authorized,true);
assert.strictEqual(eq.canEquip('reson','reson-starter-rifle','secondaryWeapon').authorized,true);
assert.strictEqual(eq.canEquip('ender','reson-starter-rifle','secondaryWeapon').authorized,false);
assert.strictEqual(
  eq.canEquip('ender','reson-starter-rifle','secondaryWeapon').reason,
  'JOB_CLASS_PERMISSION_MODEL_OPEN'
);

const state=eq.createEquipmentState('ender');
assert.deepStrictEqual(
  {mainWeapon:state.mainWeapon,secondaryWeapon:state.secondaryWeapon,autoEquipStatus:state.autoEquipStatus},
  {mainWeapon:'ender-starter-staff',secondaryWeapon:null,autoEquipStatus:'NOT_AUTHORIZED'}
);

assert.throws(()=>eq.autoEquip(),/EQUIPMENT_AUTO_EQUIP_NOT_AUTHORIZED/);
assert.throws(()=>eq.getStartingLoadout('unknown'),/EQUIPMENT_UNKNOWN_CHARACTER/);

console.log('Aetherwake equipment system foundation: PASS');
