#!/usr/bin/env node
/**
 * Original deterministic noncanonical surface-texture generator.
 * Generates the committed tileable 128x128 RGBA PNG texture assets using only
 * Node's standard library. No photos, texture packs, fonts, or licenses.
 *
 * node tools/generate_surface_textures.mjs --check # fail on asset drift
 * node tools/generate_surface_textures.mjs --write # regenerate exact assets
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
const outputDir = join(dirname(fileURLToPath(import.meta.url)), "..", "textures");
const SIZE = 128;
const smooth = t => t*t*(3-2*t);
function hash(ix, iy, seed) {
  let h = (Math.imul(ix, 374761393) ^ Math.imul(iy, 668265263) ^
    Math.imul(seed, 1442695041)) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) >>> 0) / 4294967295;
}
function noise(x, y, grid, seed) {
  const u=x*grid, v=y*grid, i=Math.floor(u), j=Math.floor(v);
  const a=smooth(u-i), b=smooth(v-j);
  const f=(ix,iy)=>hash(((ix%grid)+grid)%grid, ((iy%grid)+grid)%grid, seed);
  return (f(i,j)*(1-a)+f(i+1,j)*a)*(1-b) +
    (f(i,j+1)*(1-a)+f(i+1,j+1)*a)*b;
}
function fb(x,y,seed) {
  return 0.54*noise(x,y,8,seed) +
    0.28*noise(x,y,24,seed+11) +
    0.18*noise(x,y,48,seed+19);
}
const byte = v => Math.max(0,Math.min(255,Math.round(v*255)));
function makeTexture(kind) {
  const raw = new Uint8Array(SIZE*(1+SIZE*4));
  for (let y=0;y<SIZE;y++) {
    const row=y*(1+SIZE*4);
    for (let x=0;x<SIZE;x++) {
      const u=x/SIZE, v=y/SIZE;
      const m=fb(u,v,kind*101+3);
      const f=noise(u,v,32,kind*83+7);
      const g=noise(u,v,64,kind*61+9);
      let a,b,c;
      if (kind===0) {
        a=0.31+0.65*m; b=0.16+0.72*(1-Math.abs(2*f-1)); c=0.27+0.60*g;
      } else if (kind===1) {
        a=0.28+0.66*m; b=0.22+0.69*f; c=0.18+0.65*g;
      } else {
        a=0.15+0.73*m; b=0.17+0.70*f; c=0.12+0.78*g;
      }
      const k=row+1+x*4;
      raw[k]=byte(a);raw[k+1]=byte(b);raw[k+2]=byte(c);raw[k+3]=255;
    }
  }
  let adler=1, sum=0;
  for (const v of raw) { adler=(adler+v)%65521; sum=(sum+adler)%65521; }
  const deflated=[0x78,0x01];
  for (let i=0;i<raw.length;) {
    const len=Math.min(65535,raw.length-i),last=i+len===raw.length;
    deflated.push(last?1:0,len&255,(len>>8)&255,(~len)&255,((~len)>>8)&255);
    for(let k=0;k<len;k++) deflated.push(raw[i+k]);
    i+=len;
  }
  const ad=(sum*65536+adler)>>>0;
  deflated.push((ad>>>24)&255,(ad>>>16)&255,(ad>>>8)&255,ad&255);
  const png=[137,80,78,71,13,10,26,10];
  const add32=(arr,v)=>arr.push((v>>>24)&255,(v>>>16)&255,(v>>>8)&255,v&255);
  function chunk(tag,bytes) {
    add32(png,bytes.length);
    const all=[...Array.from(tag).map(ch=>ch.charCodeAt(0)),...bytes];
    png.push(...all);
    let crc=0xffffffff;
    for(const x of all) {
      crc^=x;
      for(let k=0;k<8;k++) crc=(crc>>>1)^((crc&1)?0xedb88320:0);
    }
    add32(png,(crc^0xffffffff)>>>0);
  }
  chunk("IHDR",[0,0,0,SIZE,0,0,0,SIZE,8,6,0,0,0]);
  chunk("IDAT",deflated);
  chunk("IEND",[]);
  return Buffer.from(png);
}
const names=[
  "terrain_microdetail.png",
  "foliage_microdetail.png",
  "water_ripple_detail.png"
];
const mode=process.argv[2]??"--check";
if (!["--check","--write"].includes(mode)) {
  console.error("Usage: node generate_surface_textures.mjs [--check|--write]");
  process.exit(2);
}
if (mode==="--write") mkdirSync(outputDir,{recursive:true});
for(let kind=0;kind<names.length;kind++) {
  const expected=makeTexture(kind);
  const path=join(outputDir,names[kind]);
  if(mode==="--write") {
    writeFileSync(path,expected);
    console.log("GENERATED_ORIGINAL_TEXTURE",names[kind],expected.length);
  } else {
    const actual=readFileSync(path);
    if (!actual.equals(expected)) {
      console.error("TEXTURE_ASSET_DRIFT",names[kind]);
      process.exitCode=1;
    } else console.log("ORIGINAL_TEXTURE_PASS",names[kind],actual.length);
  }
}
