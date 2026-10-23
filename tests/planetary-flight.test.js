'use strict';
const test=require('node:test'),assert=require('node:assert/strict');
const geo=require('../modules/planetary-geometry.js');
const flight=require('../modules/planetary-flight.js');
const R=6371;
const close=(a,b,e=1e-8)=>assert.ok(Math.abs(a-b)<e,`${a} != ${b}`);
test('flight defaults are valid and controls do not mutate caller state',()=>{
 const a=Object.freeze(flight.createState());const b=flight.advance(a,{turn:1,throttle:1,climb:1},.5,R);
 assert.equal(a.speedKmh,0);assert.equal(a.altitudeKm,2);assert.ok(b.speedKmh>0&&b.altitudeKm>2&&b.headingDeg>90);
 assert.ok(b.distanceKm>0);
});
test('positive flight crosses antimeridian with no clamping',()=>{
 let s=flight.createState({latDeg:0,lonDeg:179.9,speedKmh:950,headingDeg:90});
 for(let i=0;i<50;i++)s=flight.advance(s,{timeScale:400},1,R);
 assert.ok(s.lonDeg<0); assert.ok(s.distanceKm>5000);close(s.latDeg,0,1e-7);
});
test('flight crosses the north pole with global coordinates intact',()=>{
 let s=flight.createState({latDeg:89.8,lonDeg:35,speedKmh:950,headingDeg:0});
 for(let i=0;i<10;i++)s=flight.advance(s,{timeScale:200},1,R);
 assert.ok(s.latDeg<89.8); assert.ok(s.lonDeg<0);assert.ok(s.latDeg>=-90);
});
test('altitude, speed, heading and vertical controls clamp to limits',()=>{
 let s=flight.createState({headingDeg:359,speedKmh:948,altitudeKm:999});
 s=flight.advance(s,{turn:1,throttle:1,climb:1},1,R);
 assert.equal(s.speedKmh,flight.MAX_SPEED_KMH);assert.equal(s.altitudeKm,flight.MAX_ALTITUDE_KM);
 assert.ok(s.headingDeg<40);
 for(let i=0;i<6;i++)s=flight.advance(s,{throttle:-1,climb:-1},2,R);
 assert.equal(s.speedKmh,0);assert.ok(s.altitudeKm>=flight.MIN_ALTITUDE_KM);
});
test('distance is speed integrated and independent of heading',()=>{
 const start=flight.createState({speedKmh:360,headingDeg:90});
 const after=flight.advance(start,{turn:0,throttle:0},1,R);
 close(after.distanceKm,0.1,1e-10);
 close(geo.greatCircleDistanceKm(start,after,R),.1,1e-7);
});
test('invalid state, delta, altitude and time compression fail closed',()=>{
 assert.throws(()=>flight.createState({altitudeKm:-3}),/ALTITUDE_NEGATIVE/);
 assert.throws(()=>flight.advance(flight.createState(),{},3,R),/DT_RANGE_INVALID/);
 assert.throws(()=>flight.advance(flight.createState(),{timeScale:401},.1,R),/TIME_SCALE_INVALID/);
 assert.throws(()=>flight.advance(flight.createState(),{turn:NaN},.1,R),/TURN_INVALID/);
 assert.throws(()=>flight.advance(flight.createState(),{},.1,-5),/RADIUS_INVALID/);
});
