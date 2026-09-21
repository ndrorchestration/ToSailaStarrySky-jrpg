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
  const VERSION = '0.1.0';
  const SKY_WIDTH = 48, SKY_HEIGHT = 32;
  const ALTITUDES = Object.freeze(['low','cruise','high']);

  const LANDMARKS = Object.freeze([
    Object.freeze({id:'wake-dock',label:'WAKE DOCK',x:8,y:22,kind:'dock'}),
    Object.freeze({id:'verdant-crown',label:'VERDANT CROWN',x:17,y:15,kind:'island'}),
    Object.freeze({id:'glass-reef',label:'GLASS REEF',x:28,y:20,kind:'ruin'}),
    Object.freeze({id:'storm-gate',label:'STORM GATE',x:36,y:10,kind:'weather'}),
    Object.freeze({id:'high-choir',label:'HIGH CHOIR',x:24,y:5,kind:'floating-city'}),
  ]);

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
  function move(state,dx,dy) {
    const next=createState(state);
    next.x=clamp(next.x+dx*next.speed,0,SKY_WIDTH-1);
    next.y=clamp(next.y+dy*next.speed,0,SKY_HEIGHT-1);
    if(dx||dy) next.heading=Math.atan2(dy,dx);
    for(const mark of LANDMARKS){
      if(Math.hypot(mark.x-next.x,mark.y-next.y)<=2 && !next.discovered.includes(mark.id)) next.discovered.push(mark.id);
    }
    return next;
  }
  function changeAltitude(state,delta){
    const next=createState(state), i=ALTITUDES.indexOf(next.altitude);
    next.altitude=ALTITUDES[clamp(i+delta,0,ALTITUDES.length-1)];
    return next;
  }
  return {VERSION,SKY_WIDTH,SKY_HEIGHT,ALTITUDES:ALTITUDES.slice(),LANDMARKS:LANDMARKS.map(x=>Object.assign({},x)),WEATHER:WEATHER.map(x=>Object.assign({},x)),createState,nearestLandmark,move,changeAltitude};
}));
