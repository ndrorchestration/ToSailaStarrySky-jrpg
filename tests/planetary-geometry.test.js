'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const globe = require('../modules/planetary-geometry.js');
// A TEST FIXTURE, not the canonical Aetherwake planet radius.
const R = 6371;
const here = {latDeg:0,lonDeg:0};
const close = (actual, expected, tolerance=1e-9) => assert.ok(Math.abs(actual-expected)<=tolerance, String(actual) + ' != ' + String(expected));

test('coordinate normalization preserves longitude wrap without latitude clipping', () => {
  assert.deepEqual(globe.normalizeLatLon(0,190), {latDeg:0,lonDeg:-170});
  assert.deepEqual(globe.normalizeLatLon(100,30), {latDeg:80,lonDeg:-150});
  assert.deepEqual(globe.normalizeLatLon(-100,30), {latDeg:-80,lonDeg:-150});
  assert.deepEqual(globe.normalizeLatLon(270,10), {latDeg:-90,lonDeg:10});
  assert.equal(globe.normalizeLongitude(180), -180);
  assert.equal(globe.normalizeLongitude(-540), -180);
});

test('quarter circumference, antipodes, identity and antimeridian distances', () => {
  close(globe.greatCircleDistanceKm(here,{latDeg:0,lonDeg:90},R), Math.PI*R/2,1e-8);
  close(globe.greatCircleDistanceKm(here,{latDeg:0,lonDeg:180},R), Math.PI*R,1e-8);
  close(globe.greatCircleDistanceKm(here,here,R), 0);
  close(globe.greatCircleDistanceKm({latDeg:0,lonDeg:179},{latDeg:0,lonDeg:-179},R),R*2*Math.PI/180,1e-8);
});

test('initial heading uses east=90 and north=0, rejects coincident/antipodal points', () => {
  close(globe.initialBearingDeg(here,{latDeg:0,lonDeg:2}), 90);
  close(globe.initialBearingDeg(here,{latDeg:2,lonDeg:0}), 0);
  assert.throws(()=>globe.initialBearingDeg(here,here),/GLOBE_BEARING_UNDEFINED/);
  assert.throws(()=>globe.initialBearingDeg(here,{latDeg:0,lonDeg:180}),/GLOBE_BEARING_UNDEFINED/);
});

test('eastward great-circle travel wraps across the international date line', () => {
  const start = {latDeg:0,lonDeg:179,altitudeKm:4};
  const end=globe.destinationPoint(start,90,4*Math.PI*R/180,R);
  close(end.latDeg,0,1e-9);
  close(end.lonDeg,-177,1e-9);
  close(end.altitudeKm,4);
});

test('pole crossings remain on the globe rather than clamping at latitude 90', () => {
  const start={latDeg:85,lonDeg:40};
  const end=globe.destinationPoint(start,0,10*Math.PI*R/180,R);
  close(end.latDeg,85,1e-8);
  close(end.lonDeg,-140,1e-8);
});

test('horizon depends on altitude and occludes the far hemisphere', () => {
  close(globe.horizonAngleRad(0,R),0);
  close(globe.horizonAngleRad(R,R),Math.PI/3,1e-12);
  assert.ok(globe.horizonSurfaceDistanceKm(15,R)>globe.horizonSurfaceDistanceKm(1,R));
  const low={...here,altitudeKm:1};
  const near={latDeg:0,lonDeg:0.5};
  const far={latDeg:0,lonDeg:10};
  assert.equal(globe.hasLineOfSight(low,near,R),true);
  assert.equal(globe.hasLineOfSight(low,far,R),false);
  assert.equal(globe.hasLineOfSight({...here,altitudeKm:150},far,R),true);
  assert.equal(globe.hasLineOfSight({...here,altitudeKm:150},{latDeg:0,lonDeg:180},R),false);
});

test('two high objects can have mutual line of sight over the horizon', () => {
  const a={latDeg:0,lonDeg:0,altitudeKm:100};
  const b={latDeg:0,lonDeg:10,altitudeKm:100};
  assert.equal(globe.hasLineOfSight(a,b,R),true);
  assert.equal(globe.hasLineOfSight({...a,altitudeKm:0},{...b,altitudeKm:0},R),false);
  assert.equal(globe.hasLineOfSight(a,b,R),globe.hasLineOfSight(b,a,R));
});

test('Cartesian round trip preserves position including near longitude seam', () => {
  for(const point of [
    {latDeg:0,lonDeg:0,altitudeKm:0},
    {latDeg:46.2,lonDeg:179.8,altitudeKm:15},
    {latDeg:-81,lonDeg:-179.9,altitudeKm:0.5},
    {latDeg:90,lonDeg:0,altitudeKm:0},
  ]){
    const after=globe.fromCartesian(globe.toCartesian(point,R),R);
    close(after.latDeg,point.latDeg,1e-8);
    close(after.lonDeg,point.lonDeg,1e-8);
    close(after.altitudeKm,point.altitudeKm,1e-8);
  }
});

test('local coordinate projection is reversible near the date line', () => {
  const anchor={latDeg:20,lonDeg:179.8,altitudeKm:3};
  const target={latDeg:20.2,lonDeg:-179.9};
  const local=globe.toLocalKm(anchor,target,R);
  assert.ok(local.eastKm>0 && local.northKm>0);
  const restored=globe.fromLocalKm(anchor,local.eastKm,local.northKm,R);
  close(restored.latDeg,target.latDeg,1e-8);
  close(restored.lonDeg,target.lonDeg,1e-8);
  close(restored.altitudeKm,3);
});

test('local coordinates reject use for transplanetary routes', () => {
  assert.throws(()=>globe.toLocalKm(here,{latDeg:0,lonDeg:120},R),/GLOBE_LOCAL_RANGE_EXCEEDED/);
  assert.throws(()=>globe.fromLocalKm(here,Math.PI*R,0,R),/GLOBE_LOCAL_RANGE_EXCEEDED/);
});

test('invalid inputs fail closed, avoiding poisoned navigation or persistence', () => {
  assert.throws(()=>globe.normalizeLatLon(NaN,0),/GLOBE_LATITUDE_NONFINITE/);
  assert.throws(()=>globe.normalizePosition({latDeg:0,lonDeg:0,altitudeKm:-1}),/GLOBE_ALTITUDE_NEGATIVE/);
  assert.throws(()=>globe.hasLineOfSight(here,here,0),/GLOBE_RADIUS_INVALID/);
  assert.throws(()=>globe.destinationPoint(here,0,-1,R),/GLOBE_DISTANCE_NEGATIVE/);
  assert.throws(()=>globe.fromCartesian({xKm:0,yKm:0,zKm:0},R),/GLOBE_INSIDE_PLANET/);
});

test('geographic computations are deterministic and input objects unchanged', () => {
  const original=Object.freeze({latDeg:-60,lonDeg:181,altitudeKm:5});
  const a=globe.destinationPoint(original,37,900,R);
  assert.deepEqual(a,globe.destinationPoint(original,37,900,R));
  assert.equal(original.lonDeg,181);
  assert.equal(globe.VERSION,'0.1.0-prototype');
});
