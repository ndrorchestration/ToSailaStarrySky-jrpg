'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const tiles=require('../modules/planetary-tiles.js');
const near=(a,b,epsilon=1e-8)=>assert.ok(Math.abs(a-b)<epsilon,a+' != '+b);

test('cubed sphere uses six complete faces and stable address levels',()=>{
 assert.deepEqual(tiles.FACES,['px','nx','py','ny','pz','nz']);
 for(let l=0;l<=12;l++)assert.equal(tiles.levelSize(l),2**l);
 assert.equal(tiles.key(tiles.tileAt(0,0,0)),'px/0/0/0');
 assert.throws(()=>tiles.tileAt(0,0,-1),/LEVEL_INVALID/);
 assert.throws(()=>tiles.tileAt(0,0,13),/LEVEL_INVALID/);
});

test('equator, both poles and antimeridian map to valid finite tiles',()=>{
 for(const [lat,lon] of [[0,0],[0,179.999],[0,-179.999],[90,0],[-90,33],[48,151],[-32,-178]]) {
  const tile=tiles.tileAt(lat,lon,8);
  assert.ok(tiles.FACES.includes(tile.face));
  assert.ok(tile.x>=0&&tile.x<256&&tile.y>=0&&tile.y<256);
  const center=tiles.tileCenter(tile);
  assert.ok(Number.isFinite(center.latDeg)&&Number.isFinite(center.lonDeg));
 }
});

test('face UV roundtrip preserves every direction and globe quadrants',()=>{
 for(let lat=-85;lat<=85;lat+=17)for(let lon=-178;lon<=180;lon+=19){
  const expected=tiles.coordinatesToUnit(lat,lon);
  const {face,u,v}=tiles.faceUVFromVector(expected);
  const got=tiles.vectorFromFaceUV(face,u,v);
  expected.forEach((x,i)=>near(x,got[i]));
 }
});

test('at every zoom, tile center roundtrips to the same face and coordinates',()=>{
 for(let l=0;l<=12;l++)for(const lat of [-90,-76,-45,0,31,80,90])for(const lon of [-180,-159,-1,0,67,179]){
  const original=tiles.tileAt(lat,lon,l);
  const recovered=tiles.tileAt(tiles.tileCenter(original).latDeg,tiles.tileCenter(original).lonDeg,l);
  assert.equal(tiles.key(original),tiles.key(recovered));
 }
});

test('neighbor respects face seams and loops without invalid addresses',()=>{
 for(const pt of [[0,44.99],[0,45.01],[0,179.99],[89.99,20],[-89.99,-150]]){
  const origin=tiles.tileAt(...pt,7);
  for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]]){
   const moved=tiles.neighbor(origin,dx,dy);
   assert.ok(tiles.FACES.includes(moved.face));
   assert.equal(moved.level,7);
   assert.equal(tiles.tileAt(tiles.tileCenter(moved).latDeg,tiles.tileCenter(moved).lonDeg,7).face,moved.face);
  }
 }
});

test('neighborhood remains small, distinct and seam-safe near both poles',()=>{
 for(const [lat,lon] of [[0,0],[0,44.999],[89.9,40],[-89.9,145]]) {
  const start=tiles.tileAt(lat,lon,6);
  const ns=tiles.neighborhood(start,3);
  const unique=new Set(ns.map(tiles.key));
  assert.equal(unique.size,ns.length);
  assert.ok(ns.length>=10&&ns.length<=25);
  assert.ok(ns.some(t=>tiles.key(t)===tiles.key(start)));
 }
});

test('zero-radius neighborhoods include only the origin',()=>{
 const origin=tiles.tileAt(18,60,3);
 assert.deepEqual(tiles.neighborhood(origin,0),[origin]);
});

test('input validation fails closed without creating out-of-bounds tile keys',()=>{
 assert.throws(()=>tiles.tileAt(Infinity,0,3),/LAT_INVALID/);
 assert.throws(()=>tiles.tileAt(0,NaN,3),/LON_INVALID/);
 assert.throws(()=>tiles.tileCenter({face:'px',level:2,x:4,y:0}),/ADDRESS_INVALID/);
 assert.throws(()=>tiles.neighbor(tiles.tileAt(0,0,3),2,0),/NEIGHBOR_STEP_INVALID/);
 assert.throws(()=>tiles.neighborhood(tiles.tileAt(0,0,3),100),/RINGS_INVALID/);
 assert.throws(()=>tiles.vectorFromFaceUV('wrong',0,0),/FACE_INVALID/);
});
