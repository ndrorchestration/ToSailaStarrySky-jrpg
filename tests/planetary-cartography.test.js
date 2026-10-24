'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const cart = require('../modules/planetary-cartography.js');
const DEG = Math.PI / 180;
const sample = (lat,lon) => cart.sample(lat*DEG, lon*DEG);

test('non-canon cartography is deterministic and latitude/longitude-bound', () => {
  for (const [lat,lon] of [[0,0],[25,-82],[57,39],[-75,135],[89.8,40]]) {
    const first = sample(lat,lon), second = sample(lat,lon);
    assert.deepEqual(first,second);
    assert.ok(typeof first.biome === 'string' && first.biome.length>0);
    assert.ok(typeof first.land === 'boolean');
    assert.ok(Number.isFinite(first.relief) && first.relief>=0 && first.relief<=1);
    assert.equal(first.color.length,3);
    for(const channel of first.color)assert.ok(Number.isInteger(channel)&&channel>=0&&channel<=255);
  }
  assert.throws(()=>cart.sample(Infinity,0),/CARTOGRAPHY_INVALID_COORDINATES/);
  assert.throws(()=>cart.sample(95*DEG,0),/CARTOGRAPHY_INVALID_COORDINATES/);
  assert.throws(()=>cart.sample(0,NaN),/CARTOGRAPHY_INVALID_COORDINATES/);
});

test('sample coastlines and biome colors are periodic at the date line', () => {
  for(const lat of [-75,-39,0,27,66,85]) {
    const east=sample(lat,179.999),west=sample(lat,-180.001);
    assert.equal(east.land,west.land);
    assert.equal(east.biome,west.biome);
    for(let i=0;i<3;i++)assert.ok(Math.abs(east.color[i]-west.color[i])<=1);
  }
});

test('multiple meaningful biome belts, deep ocean and shelf coexist', () => {
  const zones=new Set();
  let land=0, ocean=0, shelf=0, ice=0;
  for(let lat=-85;lat<=85;lat+=5)for(let lon=-175;lon<=175;lon+=5) {
    const p=sample(lat,lon);zones.add(p.biome);
    land+=Number(p.land);ocean+=Number(!p.land);
    shelf+=Number(p.biome==='Coastal shelf');ice+=Number(p.biome.includes('ice')||p.biome==='Ice field');
  }
  assert.ok(land>150 && ocean>150 && land<ocean, 'fictional geography must retain extensive ocean basin');
  assert.ok(shelf>0 && ice>0 && zones.size>=8, 'world map must show coastal/ice/biome variety');
});

test('globe graticule fits the canvas and never draws the far hemisphere', () => {
  for(const [lat,lon] of [[25,-115],[0,179.9],[89,30],[-84,-130]]) {
    const pts=[],draws=[];
    const ctx={
      save(){},restore(){},beginPath(){},stroke(){draws.push(true);},
      moveTo(x,y){pts.push([x,y])},lineTo(x,y){pts.push([x,y])},
      set strokeStyle(v){},set lineWidth(v){}
    };
    cart.drawGraticule(ctx,230,230,213,lat,lon);
    assert.ok(draws.length>=15 && pts.length>50);
    for(const [x,y] of pts){
      assert.ok(Number.isFinite(x)&&Number.isFinite(y));
      assert.ok(Math.hypot(x-230,y-230)<214, 'graticule must remain on front-disc');
    }
  }
});

test('prototype globe and flight both source one shared cartographic contract',()=>{
  const fs=require('node:fs'),path=require('node:path');
  for(const relative of ['../docs/prototypes/planetary-globe.html','../docs/prototypes/planetary-flight.html']){
    const html=fs.readFileSync(path.join(__dirname,relative),'utf8');
    assert.ok(html.includes('../../modules/planetary-cartography.js'));
    assert.ok(html.includes('cart.sample('));
    assert.ok(html.includes('NON-CANON'));
    assert.ok(html.includes('To Sail the Starry Sky'));
    assert.ok(!html.includes('<title>Aetherwake'));
  }
});

test('both standalone prototype inline scripts parse in Node before browser QA',()=>{
  const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
  for(const name of ['planetary-globe.html','planetary-flight.html']) {
    const html=fs.readFileSync(path.join(__dirname,'../docs/prototypes',name),'utf8');
    const opening=html.indexOf('<script>');
    const closing=html.indexOf('</script>',opening);
    assert.ok(opening>=0 && closing>opening, 'expected inline entrypoint: '+name);
    const inline=html.slice(opening+'<script>'.length,closing);
    assert.doesNotThrow(()=>new vm.Script(inline,{filename:name}));
  }
});
