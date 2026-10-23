/*
 * Aetherwake — cubed-sphere tile addressing (prototype; no terrain assets).
 * Stable spatial keys and seam-safe neighborhood sampling for planet LOD.
 * No implicit planet radius, scene integration, discovery, or save changes.
 */
(function attach(root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.AetherPlanetaryTiles = factory();
}(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';
  const VERSION = '0.1.0-prototype';
  const MAX_LEVEL = 12; // maximum prototype level, not a production tuning choice
  const RAD = Math.PI / 180, DEG = 180 / Math.PI;
  // Outward face normal (n), right (u), up (v). n = cross(u,v).
  const FACES = Object.freeze({
    px: [[1,0,0],[0,1,0],[0,0,1]],
    nx: [[-1,0,0],[0,-1,0],[0,0,1]],
    py: [[0,1,0],[-1,0,0],[0,0,1]],
    ny: [[0,-1,0],[1,0,0],[0,0,1]],
    pz: [[0,0,1],[0,1,0],[-1,0,0]],
    nz: [[0,0,-1],[0,1,0],[1,0,0]]
  });
  function finite(n, name) { if (!Number.isFinite(n)) throw new RangeError('GLOBE_TILE_'+name+'_INVALID'); return n; }
  function levelSize(level) {
    if (!Number.isInteger(level) || level<0 || level>MAX_LEVEL) throw new RangeError('GLOBE_TILE_LEVEL_INVALID');
    return 2 ** level;
  }
  function unit(v) {
    const d=Math.hypot(...v);
    if (!(d>0)) throw new RangeError('GLOBE_TILE_VECTOR_INVALID');
    return v.map(a=>a/d);
  }
  function dot(a,b) { return a[0]*b[0]+a[1]*b[1]+a[2]*b[2]; }
  function coordinatesToUnit(latDeg,lonDeg) {
    finite(latDeg,'LAT');finite(lonDeg,'LON');
    const lat=latDeg*RAD,lon=lonDeg*RAD;
    return [Math.cos(lat)*Math.cos(lon),Math.cos(lat)*Math.sin(lon),Math.sin(lat)];
  }
  function unitToCoordinates(v) {
    if (!Array.isArray(v) || v.length!==3 || v.some(a=>!Number.isFinite(a))) throw new RangeError('GLOBE_TILE_VECTOR_INVALID');
    const [x,y,z]=unit(v);
    const longitude=((Math.atan2(y,x)*DEG+540)%360)-180;
    return {latDeg:Math.atan2(z,Math.hypot(x,y))*DEG,lonDeg:longitude};
  }
  function faceUVFromVector(vector) {
    if (!Array.isArray(vector) || vector.length!==3 || vector.some(a=>!Number.isFinite(a))) throw new RangeError('GLOBE_TILE_VECTOR_INVALID');
    const v=unit(vector);
    const x=Math.abs(v[0]),y=Math.abs(v[1]),z=Math.abs(v[2]);
    const face=x>=y&&x>=z?(v[0]>=0?'px':'nx'):y>=z?(v[1]>=0?'py':'ny'):(v[2]>=0?'pz':'nz');
    const [n,right,up]=FACES[face];const scale=dot(v,n);
    return {face,u:dot(v,right)/scale,v:dot(v,up)/scale};
  }
  function vectorFromFaceUV(face,u,v) {
    const basis=FACES[face];
    if (!basis) throw new RangeError('GLOBE_TILE_FACE_INVALID');
    finite(u,'U');finite(v,'V');
    const [n,right,up]=basis;
    return unit(n.map((base,i)=>base+right[i]*u+up[i]*v));
  }
  function address(face,u,v,level) {
    const size=levelSize(level);
    if (!FACES[face]) throw new RangeError('GLOBE_TILE_FACE_INVALID');
    finite(u,'U');finite(v,'V');
    if (u<-1-1e-10||u>1+1e-10||v<-1-1e-10||v>1+1e-10) throw new RangeError('GLOBE_TILE_UV_RANGE_INVALID');
    return Object.freeze({face,level,x:Math.min(size-1,Math.max(0,Math.floor((u+1)*size/2))),y:Math.min(size-1,Math.max(0,Math.floor((v+1)*size/2)))});
  }
  function tileAt(latDeg,lonDeg,level) {
    const {face,u,v}=faceUVFromVector(coordinatesToUnit(latDeg,lonDeg));
    return address(face,u,v,level);
  }
  function validateTile(tile) {
    if (!tile || typeof tile!=='object' || Array.isArray(tile)) throw new RangeError('GLOBE_TILE_REQUIRED');
    const size=levelSize(tile.level);
    if (!FACES[tile.face] || !Number.isInteger(tile.x) || !Number.isInteger(tile.y) || tile.x<0 || tile.y<0 || tile.x>=size || tile.y>=size) throw new RangeError('GLOBE_TILE_ADDRESS_INVALID');
    return size;
  }
  function key(tile) {
    validateTile(tile);
    return tile.face+'/'+tile.level+'/'+tile.x+'/'+tile.y;
  }
  function tileCenter(tile) {
    const size=validateTile(tile);
    const u=-1+(tile.x+0.5)*2/size,v=-1+(tile.y+0.5)*2/size;
    return unitToCoordinates(vectorFromFaceUV(tile.face,u,v));
  }
  // The neighboring tile-center direction is sampled outside the current
  // cube face and re-projected, allowing all antimeridian/polar seams.
  function neighbor(tile,dx,dy) {
    const size=validateTile(tile);
    if (!Number.isInteger(dx)||!Number.isInteger(dy)||Math.abs(dx)>1||Math.abs(dy)>1) throw new RangeError('GLOBE_TILE_NEIGHBOR_STEP_INVALID');
    if (dx===0&&dy===0) return tile;
    const u=-1+(tile.x+dx+0.5)*2/size, v=-1+(tile.y+dy+0.5)*2/size;
    const {face,u:pu,v:pv}=faceUVFromVector(vectorFromFaceUV(tile.face,u,v));
    return address(face,pu,pv,tile.level);
  }
  function neighborhood(center,rings=1) {
    validateTile(center);
    if (!Number.isInteger(rings)||rings<0||rings>5) throw new RangeError('GLOBE_TILE_RINGS_INVALID');
    const items=new Map([[key(center),center]]);
    let frontier=[center];
    for(let d=0;d<rings;d++) {
      const next=[];
      for(const tile of frontier)for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]]) {
        const adjacent=neighbor(tile,dx,dy);const id=key(adjacent);
        if(!items.has(id)) {items.set(id,adjacent);next.push(adjacent);}
      }
      frontier=next;
    }
    return [...items.values()];
  }
  return Object.freeze({VERSION,MAX_LEVEL,FACES:Object.freeze(Object.keys(FACES)),
    levelSize,coordinatesToUnit,unitToCoordinates,faceUVFromVector,vectorFromFaceUV,
    tileAt,key,tileCenter,neighbor,neighborhood});
}));
