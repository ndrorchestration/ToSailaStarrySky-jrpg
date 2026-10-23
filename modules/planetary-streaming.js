/* Aetherwake: bounded, horizon-aware tile address planner and in-memory cache.
 * Conservative face-neighbor search with a safe angular bound; no disk/network
 * fetch, mesh streaming, hidden geography disclosure, or runtime dependencies.
 */
(function attach(root,factory){
  if(typeof module==='object'&&module.exports)module.exports=factory(require('./planetary-geometry.js'),require('./planetary-tiles.js'));
  else root.AetherPlanetaryStreaming=factory(root.AetherPlanetaryGeometry,root.AetherPlanetaryTiles);
}(typeof window!=='undefined'?window:globalThis,function(geo,tiles){
  'use strict';
  const VERSION='0.1.0-prototype';
  const DEG=Math.PI/180;
  function validateMax(max){if(!Number.isInteger(max)||max<16||max>1024)throw new RangeError('GLOBE_STREAM_BUDGET_INVALID');return max;}
  function targetLevel(horizonAngle){
    if(!Number.isFinite(horizonAngle)||horizonAngle<0)throw new RangeError('GLOBE_STREAM_HORIZON_INVALID');
    return Math.max(0,Math.min(tiles.MAX_LEVEL,Math.floor(Math.log2(10/Math.max(horizonAngle,1e-8)))));
  }
  // A direction within one face tile cannot differ from its tile-center
  // direction by more than atan(2*sqrt(2)/2^level). This deliberately
  // overestimates the bound for conservative candidate admission.
  function angularPadding(level){return Math.atan(2*Math.SQRT2/tiles.levelSize(level));}
  function candidates(position,radiusKm,level,maxTiles){
    const cap=geo.horizonAngleRad(position.altitudeKm,radiusKm);
    const allowance=cap+angularPadding(level);
    const seed=tiles.tileAt(position.latDeg,position.lonDeg,level);
    const seen=new Set([tiles.key(seed)]),queue=[seed],selected=[];
    let index=0;
    while(index<queue.length){
      const tile=queue[index++];
      const center=tiles.tileCenter(tile);
      const distance=geo.separationRad(position,center);
      if(distance>allowance+1e-12)continue;
      selected.push(tile);
      if(selected.length>maxTiles)return null;
      for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]]){
        const other=tiles.neighbor(tile,dx,dy);
        const key=tiles.key(other);
        if(!seen.has(key)){seen.add(key);queue.push(other);}
      }
      if(queue.length>maxTiles*10)return null; // fail to lower LOD, never hang
    }
    return selected;
  }
  function plan(position,radiusKm,options){
    const o=options||{},maxTiles=validateMax(o.maxTiles===undefined?256:o.maxTiles);
    const p=geo.normalizePosition(position);
    const radians=geo.horizonAngleRad(p.altitudeKm,radiusKm);
    let level=o.level===undefined?targetLevel(radians):o.level;
    tiles.levelSize(level);
    let found=null, downgraded=false;
    for(;level>=0;level--){
      found=candidates(p,radiusKm,level,maxTiles);
      if(found)break;
      downgraded=true;
    }
    if(!found)throw new Error('GLOBE_STREAM_PLAN_UNAVAILABLE');
    return Object.freeze({
      level, downgraded, horizonKm:geo.horizonSurfaceDistanceKm(p.altitudeKm,radiusKm),
      tiles:Object.freeze(found), keys:Object.freeze(found.map(tiles.key))
    });
  }
  function createCache(maxEntries=256){
    if(!Number.isInteger(maxEntries)||maxEntries<1||maxEntries>16384)throw new RangeError('GLOBE_STREAM_CACHE_BUDGET_INVALID');
    const entries=new Map();let hits=0,misses=0,evictions=0;
    function use(tile,factory){
      const id=tiles.key(tile);
      if(entries.has(id)){
        const val=entries.get(id);entries.delete(id);entries.set(id,val);hits++;return val;
      }
      if(typeof factory!=='function')throw new TypeError('GLOBE_STREAM_FACTORY_REQUIRED');
      const value=factory(tile);
      misses++;
      entries.set(id,value);
      if(entries.size>maxEntries){entries.delete(entries.keys().next().value);evictions++;}
      return value;
    }
    return Object.freeze({use,has:(tile)=>entries.has(tiles.key(tile)),
      stats:()=>Object.freeze({size:entries.size,hits,misses,evictions,maxEntries}),
      clear:()=>{entries.clear();hits=0;misses=0;evictions=0;}});
  }
  return Object.freeze({VERSION,targetLevel,angularPadding,plan,createCache});
}));
