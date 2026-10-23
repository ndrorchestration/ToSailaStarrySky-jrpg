'use strict';
const test=require('node:test'),assert=require('node:assert/strict');
const geo=require('../modules/planetary-geometry.js');
const tiles=require('../modules/planetary-tiles.js');
const stream=require('../modules/planetary-streaming.js');
const R=6371;
test('horizon planning selects nearby bounded tile candidates at multiple altitudes',()=>{
 for(const alt of [0.1,2,20,100,1000]){
  const p={latDeg:34,lonDeg:-114,altitudeKm:alt};const result=stream.plan(p,R);
  assert.ok(result.tiles.length>0&&result.tiles.length<=256);
  assert.equal(new Set(result.keys).size,result.keys.length);
  assert.ok(result.keys.includes(tiles.key(tiles.tileAt(p.latDeg,p.lonDeg,result.level))));
  assert.ok(result.horizonKm>0);
 }
});
test('seam and polar neighborhoods contain observed points throughout visible cap',()=>{
 for(const p of [
  {latDeg:0,lonDeg:179.9,altitudeKm:2},
  {latDeg:89.8,lonDeg:40,altitudeKm:20},
  {latDeg:-89.8,lonDeg:-140,altitudeKm:20},
  {latDeg:0,lonDeg:45,altitudeKm:100},
  {latDeg:30,lonDeg:-115,altitudeKm:1000},
 ]){
  const result=stream.plan(p,R);
  const known=new Set(result.keys);
  for(let ring=0;ring<=6;ring++)for(let bearing=0;bearing<360;bearing+=5){
   const sample=geo.destinationPoint(p,bearing,result.horizonKm*ring/6,R);
   const key=tiles.key(tiles.tileAt(sample.latDeg,sample.lonDeg,result.level));
   assert.ok(known.has(key),`missing ${key}, ${JSON.stringify(p)} level=${result.level} horizon=${result.horizonKm}`);
  }
 }
});
test('angular padding covers cubed-sphere tile corners without legacy 2x over-padding',()=>{
 const angle=(a,b)=>Math.acos(Math.max(-1,Math.min(1,a.reduce((sum,x,i)=>sum+x*b[i],0))));
 for(const level of [0,1,2,4,8,12]){
  const size=tiles.levelSize(level);
  const coords=[0,Math.floor((size-1)/2),size-1];
  for(const face of tiles.FACES)for(const x of coords)for(const y of coords){
   const tile={face,level,x,y};
   const center=tiles.coordinatesToUnit(tiles.tileCenter(tile).latDeg,tiles.tileCenter(tile).lonDeg);
   for(const cx of [x,x+1])for(const cy of [y,y+1]){
    const u=-1+cx*2/size,v=-1+cy*2/size;
    const corner=tiles.vectorFromFaceUV(face,u,v);
    assert.ok(angle(center,corner)<=stream.angularPadding(level)+1e-12,
      `padding missed ${face}/${level}/${x}/${y}`);
   }
  }
 }
 const level=6,size=tiles.levelSize(level);
 assert.ok(stream.angularPadding(level)<Math.atan(2*Math.SQRT2/size));
});
test('small tile budget triggers safe coarser LOD without exceeding cap',()=>{
 const p={latDeg:42,lonDeg:-79,altitudeKm:200};
 const plan=stream.plan(p,R,{level:11,maxTiles:25});
 assert.ok(plan.downgraded);
 assert.ok(plan.level<11);
 assert.ok(plan.tiles.length<=25);
});
test('cache is bounded LRU, loads once, and exposes eviction counters',()=>{
 const cache=stream.createCache(2);
 const a=tiles.tileAt(0,0,5),b=tiles.tileAt(0,22,5),c=tiles.tileAt(0,70,5);
 let created=0;
 const factory=t=>({id:tiles.key(t),marker:++created});
 const av=cache.use(a,factory);cache.use(b,factory);assert.equal(cache.use(a,factory),av);
 cache.use(c,factory);
 assert.equal(cache.has(a),true);assert.equal(cache.has(b),false);assert.equal(cache.stats().size,2);
 assert.equal(cache.stats().hits,1);assert.equal(cache.stats().misses,3);assert.equal(cache.stats().evictions,1);
 cache.clear();assert.equal(cache.stats().size,0);assert.equal(cache.stats().misses,0);
});
test('invalid altitude, explicit LOD or budget fail closed',()=>{
 const p={latDeg:0,lonDeg:0,altitudeKm:2};
 assert.throws(()=>stream.plan(p,R,{maxTiles:2}),/BUDGET_INVALID/);
 assert.throws(()=>stream.plan(p,R,{level:13}),/LEVEL_INVALID/);
 assert.throws(()=>stream.plan(p,-1),/RADIUS_INVALID/);
 assert.throws(()=>stream.createCache(0),/CACHE_BUDGET_INVALID/);
 assert.throws(()=>stream.targetLevel(-1),/HORIZON_INVALID/);
});
