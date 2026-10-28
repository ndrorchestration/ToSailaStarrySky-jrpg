/* To Sail the Starry Sky — NON-CANON surface-material handoff prototype.
 * Carries cubed-sphere visible tile addresses to renderer-facing material
 * hints. It does NOT create heightfields, physics, saves, discoveries or routes.
 * Godot flight_slice shaders #485 are art evidence, not planet source data.
 */
(function attach(root,factory){
  if(typeof module==='object'&&module.exports)
    module.exports=factory(require('./planetary-geometry.js'),
      require('./planetary-tiles.js'),require('./planetary-streaming.js'),
      require('./planetary-cartography.js'));
  else root.AetherPlanetarySurfaceHandoff=factory(
    root.AetherPlanetaryGeometry,root.AetherPlanetaryTiles,
    root.AetherPlanetaryStreaming,root.AetherPlanetaryCartography);
}(typeof window!=='undefined'?window:globalThis,function(geo,tiles,stream,cart){
  'use strict';
  const VERSION='0.1.0-noncanon-handoff';
  const DEG=Math.PI/180;
  const NO_AUTHORITY=Object.freeze({
    elevation:'UNSPECIFIED',collision:'UNSPECIFIED',landable:'UNSPECIFIED',
    discovery:'UNSPECIFIED',route:'UNSPECIFIED',story:'UNSPECIFIED'
  });
  function quality(mode){
    const selected=mode===undefined?'high':mode;
    if(selected!=='high'&&selected!=='low')
      throw new RangeError('SURFACE_HANDOFF_QUALITY_INVALID');
    return selected;
  }
  function materialFamily(art){
    if(!art.land)return art.biome==='Polar ice'?'polar-ice':'water';
    if(art.biome==='Ice field')return 'ice';
    if(art.biome==='Alpine')return 'alpine-rock';
    if(/forest|woodland|rainforest/i.test(art.biome))return 'woodland';
    return 'ground';
  }
  function surfaceAt(position,qualityMode){
    const p=geo.normalizePosition(position);
    const mode=quality(qualityMode);
    const art=cart.sample(p.latDeg*DEG,p.lonDeg*DEG);
    const family=materialFamily(art);
    const alpineDetail=family==='alpine-rock'&&mode==='high';
    const material=Object.freeze({
      family,baseColorRgb:Object.freeze([...art.color]),
      reliefColorHint:art.relief,quality:mode,
      // Requested features only. True Godot shading needs actual normal,
      // terrain height and local snowline supplied by the gameplay renderer.
      cliffProjection:alpineDetail?'REQUIRES_LOCAL_NORMAL':'OFF',
      snowRockBlend:alpineDetail?'REQUIRES_LOCAL_ELEVATION':'OFF'
    });
    return Object.freeze({
      coordinate:Object.freeze({latDeg:p.latDeg,lonDeg:p.lonDeg}),
      biome:art.biome,land:art.land,
      material,
      provenance:Object.freeze({
        studyOnly:true,cartographyVersion:cart.VERSION,
        source:'planetary-cartography.sample',heightUnit:'NONE'
      }),
      authority:NO_AUTHORITY
    });
  }
  function planVisibleSurface(position,radiusKm,options){
    const opts=options||{};
    const mode=quality(opts.quality);
    const p=geo.normalizePosition(position);
    const request={};
    if(opts.maxTiles!==undefined)request.maxTiles=opts.maxTiles;
    if(opts.level!==undefined)request.level=opts.level;
    const visible=stream.plan(p,radiusKm,request);
    const requests=visible.tiles.map((tile,index)=>{
      const center=tiles.tileCenter(tile);
      return Object.freeze({
        tileKey:visible.keys[index],
        tile:Object.freeze({...tile}),
        center:Object.freeze({latDeg:center.latDeg,lonDeg:center.lonDeg}),
        surface:surfaceAt(center,mode)
      });
    });
    return Object.freeze({
      schema:VERSION,studyOnly:true,
      observer:Object.freeze({...p}),
      lodLevel:visible.level,lodDowngraded:visible.downgraded,
      horizonKm:visible.horizonKm,
      tileCount:requests.length,
      tiles:Object.freeze(requests),
      authority:NO_AUTHORITY
    });
  }
  return Object.freeze({VERSION,NO_AUTHORITY,surfaceAt,planVisibleSurface});
}));
