/* Aetherwake isolated geodesic airship flight study. Not production physics. */
(function attach(root,factory){
  if(typeof module==='object'&&module.exports)module.exports=factory(require('./planetary-geometry.js'));
  else root.AetherPlanetaryFlight=factory(root.AetherPlanetaryGeometry);
}(typeof window!=='undefined'?window:globalThis,function(geo){
  'use strict';
  const VERSION='0.1.0-prototype';
  const MAX_SPEED_KMH=950, TURN_DEG_PER_SECOND=35, ACCEL_KMH_PER_SECOND=180;
  const DECEL_KMH_PER_SECOND=230, CLIMB_KM_PER_SECOND=1.5;
  const MIN_ALTITUDE_KM=0.1,MAX_ALTITUDE_KM=1000;
  const clamp=(x,min,max)=>Math.max(min,Math.min(max,x));
  function number(x,field){if(!Number.isFinite(x))throw new RangeError('GLOBE_FLIGHT_'+field+'_INVALID');return x;}
  function createState(overrides){
    const o=overrides||{};
    const p=geo.normalizePosition({latDeg:o.latDeg===undefined?25:o.latDeg,lonDeg:o.lonDeg===undefined?-115:o.lonDeg,altitudeKm:o.altitudeKm===undefined?2:o.altitudeKm});
    const headingDeg=((number(o.headingDeg===undefined?90:o.headingDeg,'HEADING')%360)+360)%360;
    const speedKmh=number(o.speedKmh===undefined?0:o.speedKmh,'SPEED');
    const distanceKm=number(o.distanceKm===undefined?0:o.distanceKm,'DISTANCE');
    if(speedKmh<0||speedKmh>MAX_SPEED_KMH||distanceKm<0||p.altitudeKm<MIN_ALTITUDE_KM||p.altitudeKm>MAX_ALTITUDE_KM)
      throw new RangeError('GLOBE_FLIGHT_STATE_RANGE_INVALID');
    return {...p,headingDeg,speedKmh,distanceKm};
  }
  function advance(state,control,dtSeconds,radiusKm){
    const s=createState(state),c=control||{};
    number(dtSeconds,'DT');
    if(dtSeconds<0||dtSeconds>2)throw new RangeError('GLOBE_FLIGHT_DT_RANGE_INVALID');
    // Let geometry validate the radius even when stationary.
    geo.horizonAngleRad(s.altitudeKm,radiusKm);
    const turn=clamp(number(c.turn===undefined?0:c.turn,'TURN'),-1,1);
    const throttle=clamp(number(c.throttle===undefined?0:c.throttle,'THROTTLE'),-1,1);
    const climb=clamp(number(c.climb===undefined?0:c.climb,'CLIMB'),-1,1);
    const timeScale=c.timeScale===undefined?1:number(c.timeScale,'TIME_SCALE');
    if(timeScale<1||timeScale>400)throw new RangeError('GLOBE_FLIGHT_TIME_SCALE_INVALID');
    const headingDeg=((s.headingDeg+turn*TURN_DEG_PER_SECOND*dtSeconds)%360+360)%360;
    const speedKmh=clamp(s.speedKmh+(throttle>=0?ACCEL_KMH_PER_SECOND*throttle:DECEL_KMH_PER_SECOND*throttle)*dtSeconds,0,MAX_SPEED_KMH);
    const altitudeKm=clamp(s.altitudeKm+climb*CLIMB_KM_PER_SECOND*dtSeconds*10,MIN_ALTITUDE_KM,MAX_ALTITUDE_KM);
    const deltaKm=(s.speedKmh+speedKmh)*0.5*dtSeconds*timeScale/3600;
    const position=geo.destinationPoint({...s,altitudeKm},headingDeg,deltaKm,radiusKm);
    // Parallel-transport forward motion: retaining a fixed compass bearing
    // after crossing a pole reverses the ship back toward that pole.
    // The arrival heading is the reverse geodesic bearing + 180 degrees.
    let arrivalHeadingDeg=headingDeg;
    if(deltaKm>1e-8 && deltaKm<Math.PI*radiusKm-1e-8){
      arrivalHeadingDeg=(geo.initialBearingDeg(position,s)+180)%360;
    }
    return {...position,headingDeg:arrivalHeadingDeg,speedKmh,distanceKm:s.distanceKm+deltaKm};
  }
  return Object.freeze({VERSION,MAX_SPEED_KMH,MIN_ALTITUDE_KM,MAX_ALTITUDE_KM,createState,advance});
}));
