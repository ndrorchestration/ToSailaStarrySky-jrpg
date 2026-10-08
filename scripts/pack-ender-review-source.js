/* Mechanical source-sheet conversion; requires Sharp in the authoring environment. */
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require('sharp');
const base = path.resolve(__dirname, '..');
const dir = path.join(base, 'art-staging/field/ender');
const specs = {
  idle: {cols:4, rows:2, scale:67/490, fps:8},
  walk: {cols:3, rows:2, scale:67/475, fps:10},
  talk: {cols:2, rows:2, scale:67/610, fps:6},
  focus: {cols:3, rows:2, scale:67/490, fps:12},
  attack: {cols:4, rows:2, scale:67/600, fps:15},
};
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
async function main() {
  const receipt = {status:'CANDIDATE_NOT_ADMITTED', frameSize:[64,96], footLine:93,
    alphaCutoff:128, filter:'nearest', appearanceSha256:'619517944ebe12b295bf5f780abb1a49bce2449230654fb8c49b11e8380546fd', actions:{}};
  for (const [action,spec] of Object.entries(specs)) {
    const sourcePath = path.join(dir,'sources',action+'-source-20261008.png');
    const source = fs.readFileSync(sourcePath);
    const {data,info} = await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    const count = spec.cols*spec.rows;
    const strip = Buffer.alloc(64*count*96*4);
    const boxes=[];
    const frameDir=path.join(dir,action); fs.mkdirSync(frameDir,{recursive:true});
    for(let i=0;i<count;i++) {
      const cell={left:Math.round((i%spec.cols)*info.width/spec.cols),top:Math.round(Math.floor(i/spec.cols)*info.height/spec.rows),
        right:Math.round((i%spec.cols+1)*info.width/spec.cols),bottom:Math.round((Math.floor(i/spec.cols)+1)*info.height/spec.rows)};
      let l=cell.right,t=cell.bottom,r=cell.left,b=cell.top;
      for(let y=cell.top;y<cell.bottom;y++) for(let x=cell.left;x<cell.right;x++) {
        if(data[(y*info.width+x)*4+3]>128){l=Math.min(l,x);t=Math.min(t,y);r=Math.max(r,x+1);b=Math.max(b,y+1);}
      }
      if(r<=l||b<=t) throw Error(action+' empty source cell '+i);
      let cw=r-l,ch=b-t,crop=Buffer.alloc(cw*ch*4);
      for(let y=t;y<b;y++) for(let x=l;x<r;x++) {
        const si=(y*info.width+x)*4,di=((y-t)*cw+x-l)*4;
        if(data[si+3]>128){data.copy(crop,di,si,si+3);crop[di+3]=255;}
      }
      // Retain the connected figure; sheet cells can contain isolated export specks.
      const seen=new Uint8Array(cw*ch), components=[];
      for(let p=0;p<seen.length;p++) {
        if(seen[p]||!crop[p*4+3])continue;
        const pixels=[p];seen[p]=1;
        for(let q=0;q<pixels.length;q++) {
          const v=pixels[q],x=v%cw,y=Math.floor(v/cw);
          for(let oy=-1;oy<=1;oy++)for(let ox=-1;ox<=1;ox++) {
            const nx=x+ox,ny=y+oy,n=ny*cw+nx;
            if(nx>=0&&nx<cw&&ny>=0&&ny<ch&&!seen[n]&&crop[n*4+3]){seen[n]=1;pixels.push(n);}
          }
        }
        components.push(pixels);
      }
      components.sort((a,b)=>b.length-a.length);
      for(const pixels of components.slice(1))for(const p of pixels)crop.fill(0,p*4,p*4+4);
      let ml=cw,mt=ch,mr=0,mb=0;
      for(const p of components[0]){const x=p%cw,y=Math.floor(p/cw);ml=Math.min(ml,x);mt=Math.min(mt,y);mr=Math.max(mr,x+1);mb=Math.max(mb,y+1);}
      const trimmed=Buffer.alloc((mr-ml)*(mb-mt)*4);
      for(let y=mt;y<mb;y++)crop.copy(trimmed,(y-mt)*(mr-ml)*4,(y*cw+ml)*4,(y*cw+mr)*4);
      l+=ml;t+=mt;r=l+mr-ml;b=t+mb-mt;cw=mr-ml;ch=mb-mt;crop=trimmed;
      const w=Math.round(cw*spec.scale),h=Math.round(ch*spec.scale);
      if(w>62||h>92) throw Error(action+' frame '+i+' exceeds review cell: '+w+'x'+h);
      const raw=await sharp(crop,{raw:{width:cw,height:ch,channels:4}}).resize(w,h,{kernel:'nearest'}).raw().toBuffer();
      let visibleBottom=-1;
      for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(raw[(y*w+x)*4+3])visibleBottom=y;
      const dx=Math.floor((64-w)/2),dy=93-visibleBottom,frame=Buffer.alloc(64*96*4);
      for(let y=0;y<h;y++)for(let x=0;x<w;x++) {
        const si=(y*w+x)*4,di=((y+dy)*64+x+dx)*4;
        raw.copy(frame,di,si,si+4);
        raw.copy(strip,((y+dy)*(64*count)+i*64+x+dx)*4,si,si+4);
      }
      await sharp(frame,{raw:{width:64,height:96,channels:4}}).png().toFile(path.join(frameDir,'frame-'+String(i+1).padStart(2,'0')+'.png'));
      boxes.push({source:[l,t,r,b],scale:spec.scale,placed:[dx,dy,w,h],removedDisconnectedPixels:components.slice(1).reduce((n,c)=>n+c.length,0),sha256:hash(frame)});
    }
    const output=await sharp(strip,{raw:{width:64*count,height:96,channels:4}}).png().toBuffer();
    fs.writeFileSync(path.join(dir,'candidate','field-'+action+'.png'),output);
    receipt.actions[action]={frames:count,fps:spec.fps,sourceSha256:hash(source),assetSha256:hash(output),conversion:boxes};
  }
  fs.writeFileSync(path.join(dir,'candidate/conversion.json'),JSON.stringify(receipt,null,2)+'\n');
  console.log('ENDER_REVIEW_CONVERSION=PACKED_32_FRAMES');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
