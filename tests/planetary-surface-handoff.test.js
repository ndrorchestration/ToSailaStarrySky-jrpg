'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const geo=require('../modules/planetary-geometry.js');
const tiles=require('../modules/planetary-tiles.js');
const stream=require('../modules/planetary-streaming.js');
const cart=require('../modules/planetary-cartography.js');
const handoff=require('../modules/planetary-surface-handoff.js');
const DEG=Math.PI/180;
const R=6371; // geometry TEST fixture only, never canonical radius
test('globe cartography feeds a bounded visual-only material record',()=>{
  for(const [lat,lon] of [[0,0],[25,-82],[57,39],[-75,135],[89.8,40]]){
    const p={latDeg:lat,lonDeg:lon,altitudeKm:3};
    const original=cart.sample(lat*DEG,lon*DEG);
    const result=handoff.surfaceAt(p);
    assert.equal(result.biome,original.biome);
    assert.equal(result.land,original.land);
    assert.deepEqual(result.material.baseColorRgb,original.color);
    assert.equal(result.material.reliefColorHint,original.relief);
    assert.equal(result.material.quality,'high');
    assert.equal(result.provenance.studyOnly,true);
    assert.equal(result.provenance.heightUnit,'NONE');
    assert.ok(Object.isFrozen(result.material.baseColorRgb));
    assert.ok(Object.isFrozen(result));
    assert.equal(result.authority.elevation,'UNSPECIFIED');
    assert.equal(result.authority.collision,'UNSPECIFIED');
    assert.equal(result.authority.landable,'UNSPECIFIED');
    assert.equal(result.authority.discovery,'UNSPECIFIED');
    assert.equal(result.authority.route,'UNSPECIFIED');
    assert.equal(result.authority.story,'UNSPECIFIED');
    assert.equal('heightMeters' in result,false);
    assert.equal('canLand' in result,false);
  }
});
test('planetary surface handoff follows longitude wrapping and pole normalization',()=>{
  for(const lat of [-82,-35,0,35,82]){
    const a=handoff.surfaceAt({latDeg:lat,lonDeg:179.999});
    const b=handoff.surfaceAt({latDeg:lat,lonDeg:-180.001});
    assert.equal(a.biome,b.biome);
    assert.deepEqual(a.material.baseColorRgb,b.material.baseColorRgb);
  }
  const p=handoff.surfaceAt({latDeg:95,lonDeg:40});
  const canonical=handoff.surfaceAt({latDeg:85,lonDeg:-140});
  assert.deepEqual(p.material,canonical.material);
  assert.deepEqual(p.coordinate,canonical.coordinate);
});
test('alpine shader features are requests, never invented normals or heights',()=>{
  let alpine=null;
  for(let lat=37;lat<=75 && !alpine;lat+=2)
    for(let lon=-178;lon<180;lon+=3){
      const s=handoff.surfaceAt({latDeg:lat,lonDeg:lon});
      if(s.material.family==='alpine-rock'){alpine={latDeg:lat,lonDeg:lon};break;}
    }
  assert.ok(alpine,'sampled fictional planet must contain testable alpine terrain');
  const high=handoff.surfaceAt(alpine,'high');
  const low=handoff.surfaceAt(alpine,'low');
  assert.equal(high.material.cliffProjection,'REQUIRES_LOCAL_NORMAL');
  assert.equal(high.material.snowRockBlend,'REQUIRES_LOCAL_ELEVATION');
  assert.equal(low.material.cliffProjection,'OFF');
  assert.equal(low.material.snowRockBlend,'OFF');
  assert.deepEqual(low.material.baseColorRgb,high.material.baseColorRgb);
  assert.equal(high.authority.collision,'UNSPECIFIED');
});
test('horizon-aware tile planner hands off the exact selected cube-sphere keys',()=>{
  for(const p of [
    {latDeg:25,lonDeg:-82,altitudeKm:2},
    {latDeg:0,lonDeg:179.9,altitudeKm:10},
    {latDeg:89.7,lonDeg:40,altitudeKm:20},
    {latDeg:-89.7,lonDeg:-140,altitudeKm:100},
  ]){
    const expected=stream.plan(p,R,{maxTiles:64});
    const plan=handoff.planVisibleSurface(p,R,{maxTiles:64,quality:'high'});
    assert.equal(plan.schema,handoff.VERSION);
    assert.equal(plan.studyOnly,true);
    assert.equal(plan.tileCount,expected.keys.length);
    assert.equal(plan.lodLevel,expected.level);
    assert.equal(plan.lodDowngraded,expected.downgraded);
    assert.deepEqual(plan.tiles.map(t=>t.tileKey),expected.keys);
    assert.equal(new Set(plan.tiles.map(t=>t.tileKey)).size,plan.tileCount);
    assert.ok(plan.tileCount>0&&plan.tileCount<=64);
    for(const item of plan.tiles){
      assert.equal(item.tileKey,tiles.key(item.tile));
      const center=tiles.tileCenter(item.tile);
      assert.deepEqual(item.center,center);
      assert.equal(item.surface.biome,cart.sample(center.latDeg*DEG,center.lonDeg*DEG).biome);
      assert.equal(item.surface.authority.elevation,'UNSPECIFIED');
      assert.ok(Object.isFrozen(item.surface));
    }
  }
});
test('planner falls back to the lower LOD safely under a constrained tile budget',()=>{
  const p={latDeg:42,lonDeg:-79,altitudeKm:200};
  const expected=stream.plan(p,R,{level:11,maxTiles:25});
  const receipt=handoff.planVisibleSurface(p,R,{level:11,maxTiles:25,quality:'low'});
  assert.equal(receipt.lodLevel,expected.level);
  assert.equal(receipt.lodDowngraded,true);
  assert.ok(receipt.tileCount<=25);
  assert.ok(receipt.tiles.every(t=>t.surface.material.cliffProjection==='OFF'));
});
test('invalid radii, positions, quality and budgets fail closed',()=>{
  const p={latDeg:0,lonDeg:0,altitudeKm:2};
  assert.throws(()=>handoff.surfaceAt({...p,latDeg:NaN}),/NONFINITE/);
  assert.throws(()=>handoff.surfaceAt(p,'ultra'),/SURFACE_HANDOFF_QUALITY_INVALID/);
  assert.throws(()=>handoff.planVisibleSurface(p,-1),/GLOBE_RADIUS_INVALID/);
  assert.throws(()=>handoff.planVisibleSurface(p,R,{maxTiles:2}),/GLOBE_STREAM_BUDGET_INVALID/);
  assert.throws(()=>handoff.planVisibleSurface(p,R,{level:13}),/GLOBE_TILE_LEVEL_INVALID/);
});
test('the planet flight UI exposes the handoff as a labeled visual-only study',()=>{
  const fs=require('node:fs'),path=require('node:path');
  const html=fs.readFileSync(path.join(__dirname,'../docs/prototypes/planetary-flight.html'),'utf8');
  assert.ok(html.includes('../../modules/planetary-surface-handoff.js'));
  assert.ok(html.includes('surface.surfaceAt('));
  assert.ok(html.includes('id="surfaceMaterial"'));
  assert.ok(html.includes('Surface request · noncanon'));
});
