/*
 * Aetherwake — Air Navigation Foundation
 * Pure-data sky geography and travel-state contract. This deliberately does
 * not authorize combat, economy, or story progression.
 */
(function attach(root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.AetherAirNavigation = factory();
}(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';
  const VERSION = '0.3.0';
  const SKY_WIDTH = 48, SKY_HEIGHT = 32;
  const ALTITUDES = Object.freeze(['low','cruise','high']);

  const LANDMARKS = Object.freeze([
    Object.freeze({id:'wake-dock',label:'WAKE DOCK',x:8,y:22,kind:'dock',dockable:true}),
    Object.freeze({id:'verdant-crown',label:'VERDANT CROWN',x:17,y:15,kind:'island',dockable:true}),
    Object.freeze({id:'glass-reef',label:'GLASS REEF',x:28,y:20,kind:'ruin',dockable:false}),
    Object.freeze({id:'storm-gate',label:'STORM GATE',x:36,y:10,kind:'weather',dockable:false}),
    Object.freeze({id:'high-choir',label:'HIGH CHOIR',x:24,y:5,kind:'floating-city',dockable:true}),
  ]);

  const SKY_ROUTES = Object.freeze([
    Object.freeze({id:'rootline-west',from:'wake-dock',to:'verdant-crown',label:'ROOTLINE WEST'}),
    Object.freeze({id:'reef-run',from:'verdant-crown',to:'glass-reef',label:'REEF RUN'}),
    Object.freeze({id:'choir-ascent',from:'verdant-crown',to:'high-choir',label:'CHOIR ASCENT'}),
    Object.freeze({id:'storm-thread',from:'glass-reef',to:'storm-gate',label:'STORM THREAD'}),
  ]);

  const WEATHER_ZONES = Object.freeze([
    Object.freeze({id:'crosswind-belt',weatherId:'crosswind',x:19,y:11,radius:6,altitudes:['low','cruise']}),
    Object.freeze({id:'storm-gate-squall',weatherId:'aether-squall',x:36,y:10,radius:7,altitudes:['cruise','high']}),
  ]);

  const SKY_ENCOUNTERS = Object.freeze([
    Object.freeze({id:'skyPredator',altitudes:['low','cruise'],weight:6}),
    Object.freeze({id:'windShear',altitudes:['cruise','high'],weight:4}),
    Object.freeze({id:'aetherLeak',altitudes:['high'],weight:3}),
  ]);
  const ENCOUNTER_STEP_THRESHOLD = 7;

  const WEATHER = Object.freeze([
    Object.freeze({id:'clear',label:'CLEAR WAKE',phaseRisk:0}),
    Object.freeze({id:'crosswind',label:'CROSSWIND',phaseRisk:1}),
    Object.freeze({id:'aether-squall',label:'AETHER SQUALL',phaseRisk:2}),
  ]);

  function clamp(v,a,b){ return Math.max(a,Math.min(b,v)); }
  function createState(overrides) {
    const o=overrides||{};
    return {
      x: clamp(Number.isFinite(o.x)?o.x:8,0,SKY_WIDTH-1),
      y: clamp(Number.isFinite(o.y)?o.y:22,0,SKY_HEIGHT-1),
      altitude: ALTITUDES.includes(o.altitude)?o.altitude:'cruise',
      heading: Number.isFinite(o.heading)?o.heading:0,
      speed: clamp(Number.isFinite(o.speed)?o.speed:1,0,3),
      weatherId: WEATHER.some(w=>w.id===o.weatherId)?o.weatherId:'clear',
      discovered: Array.isArray(o.discovered)?o.discovered.slice():['wake-dock'],
      discoveredRoutes: Array.isArray(o.discoveredRoutes)?o.discoveredRoutes.slice():[],
      mooredLandmarkId: (typeof o.mooredLandmarkId==='string' &&
        LANDMARKS.some(mark=>mark.id===o.mooredLandmarkId && mark.dockable &&
          Math.hypot(mark.x-(Number.isFinite(o.x)?o.x:8),mark.y-(Number.isFinite(o.y)?o.y:22))<=1.5))
        ? o.mooredLandmarkId : null,
      encounterSteps: Number.isInteger(o.encounterSteps)?Math.max(0,o.encounterSteps):0,
      encounterSeed: Number.isInteger(o.encounterSeed)?o.encounterSeed:0,
    };
  }
  function nearestLandmark(state) {
    let best=null,dist=Infinity;
    for (const mark of LANDMARKS) {
      const d=Math.hypot(mark.x-state.x,mark.y-state.y);
      if(d<dist){best=mark;dist=d;}
    }
    return best ? {landmark:Object.assign({},best),distance:dist} : null;
  }
  function weatherAt(state) {
    for (const zone of WEATHER_ZONES) {
      if (!zone.altitudes.includes(state.altitude)) continue;
      if (Math.hypot(zone.x-state.x,zone.y-state.y)<=zone.radius) {
        return Object.assign({}, WEATHER.find(w=>w.id===zone.weatherId));
      }
    }
    return Object.assign({}, WEATHER[0]);
  }
  function routeDiscovery(next) {
    for (const route of SKY_ROUTES) {
      const a=LANDMARKS.find(mark=>mark.id===route.from), b=LANDMARKS.find(mark=>mark.id===route.to);
      if (!a || !b) continue;
      const dx=b.x-a.x, dy=b.y-a.y, len2=dx*dx+dy*dy;
      const t=len2 ? clamp(((next.x-a.x)*dx+(next.y-a.y)*dy)/len2,0,1) : 0;
      const px=a.x+t*dx, py=a.y+t*dy;
      if (Math.hypot(next.x-px,next.y-py)<=1.75 && !next.discoveredRoutes.includes(route.id)) next.discoveredRoutes.push(route.id);
    }
  }
  function dockingCheck(state) {
    const nearest=nearestLandmark(state);
    if (!nearest || nearest.distance>1.5 || !nearest.landmark.dockable) return {available:false,landmark:null};
    return {available:true,landmark:nearest.landmark};
  }
  function dock(state) {
    const next=createState(state), check=dockingCheck(next);
    if (!check.available) return {ok:false,state:next,landmark:null};
    next.mooredLandmarkId=check.landmark.id; next.speed=0; next.encounterSteps=0;
    return {ok:true,state:next,landmark:check.landmark};
  }
  function undock(state) {
    const next=createState(state); next.mooredLandmarkId=null; if(next.speed===0) next.speed=1; return next;
  }
  function move(state,dx,dy) {
    const next=createState(state);
    const startX=next.x, startY=next.y;
    next.x=clamp(next.x+dx*next.speed,0,SKY_WIDTH-1);
    next.y=clamp(next.y+dy*next.speed,0,SKY_HEIGHT-1);
    const traveled=Math.abs(next.x-startX)+Math.abs(next.y-startY);
    if(traveled>0) {
      next.mooredLandmarkId=null;
      next.heading=Math.atan2(dy,dx);
      next.encounterSteps += traveled;
    }
    for(const mark of LANDMARKS){
      if(Math.hypot(mark.x-next.x,mark.y-next.y)<=2 && !next.discovered.includes(mark.id)) next.discovered.push(mark.id);
    }
    routeDiscovery(next);
    next.weatherId=weatherAt(next).id;
    return next;
  }
  function encounterCheck(state) {
    const next=createState(state);
    if (next.encounterSteps < ENCOUNTER_STEP_THRESHOLD) return {triggered:false,state:next,enemyId:null};
    // Deterministic encounter roll: movement count + position + altitude. No frame-time RNG.
    const ai=ALTITUDES.indexOf(next.altitude);
    const roll=Math.abs(Math.imul(Math.round(next.x)+17,31)+Math.imul(Math.round(next.y)+11,47)+Math.imul(next.encounterSeed+ai+1,53))%5;
    next.encounterSteps=0; next.encounterSeed+=1;
    if(roll>1) return {triggered:false,state:next,enemyId:null};
    const candidates=SKY_ENCOUNTERS.filter(entry=>entry.altitudes.includes(next.altitude));
    const total=candidates.reduce((sum,entry)=>sum+entry.weight,0);
    let pick=Math.abs(Math.imul(next.encounterSeed+1,97)+Math.round(next.x)*13+Math.round(next.y)*7)%total;
    let enemyId=candidates[0].id;
    for(const entry of candidates){
      if(pick<entry.weight){enemyId=entry.id;break;}
      pick-=entry.weight;
    }
    return {triggered:true,state:next,enemyId};
  }
  function changeAltitude(state,delta){
    const next=createState(state), i=ALTITUDES.indexOf(next.altitude);
    next.altitude=ALTITUDES[clamp(i+delta,0,ALTITUDES.length-1)];
    next.weatherId=weatherAt(next).id;
    return next;
  }
  return {VERSION,SKY_WIDTH,SKY_HEIGHT,ALTITUDES:ALTITUDES.slice(),LANDMARKS:LANDMARKS.map(x=>Object.assign({},x)),SKY_ROUTES:SKY_ROUTES.map(x=>Object.assign({},x)),WEATHER:WEATHER.map(x=>Object.assign({},x)),WEATHER_ZONES:WEATHER_ZONES.map(x=>Object.assign({},x)),SKY_ENCOUNTERS:SKY_ENCOUNTERS.map(x=>Object.assign({},x)),ENCOUNTER_STEP_THRESHOLD,createState,nearestLandmark,weatherAt,dockingCheck,dock,undock,move,encounterCheck,changeAltitude};
}));
