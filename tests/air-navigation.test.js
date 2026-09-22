'use strict';
const assert=require('assert');
const nav=require('../modules/air-navigation.js');

assert.strictEqual(nav.VERSION,'0.4.0');
assert.deepStrictEqual(nav.ALTITUDES,['low','cruise','high']);
assert(nav.LANDMARKS.length>=5,'sky needs authored navigation landmarks');
assert(nav.SKY_ROUTES.length>=4,'sky needs authored route graph');
assert(nav.WEATHER_ZONES.length>=2,'sky needs authored weather regions');

const initial=nav.createState();
assert.strictEqual(initial.altitude,'cruise');

const moved=nav.move(initial,1,0);
assert(moved.x>initial.x,'air navigation must move independently of ground topology');

const high=nav.changeAltitude(initial,1);
assert.strictEqual(high.altitude,'high');

const clear=nav.weatherAt(initial);
assert(clear && clear.id==='clear','wake dock should begin in clear air');

const stormState=nav.createState({x:36,y:10,altitude:'high'});
const storm=nav.weatherAt(stormState);
assert.strictEqual(storm.id,'aether-squall','storm gate must expose high-altitude squall');
assert(storm.speedFactor<1,'squall must impose a travel penalty');

const dockCheck=nav.dockingCheck(nav.createState({x:8,y:22}));
assert(dockCheck.available && dockCheck.landmark.id==='wake-dock','wake dock berth unavailable');

const docked=nav.dock(nav.createState({x:8,y:22,speed:2,encounterSteps:4}));
assert(docked.ok && docked.state.mooredLandmarkId==='wake-dock' && docked.state.speed===0,'docking state invalid');
assert.strictEqual(docked.state.encounterSteps,0,'safe docking must clear pending encounter cadence');

const undocked=nav.undock(docked.state);
assert.strictEqual(undocked.mooredLandmarkId,null);
assert(undocked.speed>0,'undock must restore travel speed');

const routeProbe=nav.move(nav.createState({x:11,y:20}),1,-1);
assert(Array.isArray(routeProbe.discoveredRoutes),'route discovery ledger missing');

const routeProjection=nav.nearestRoute(nav.createState({x:12,y:19}));
assert(routeProjection && routeProjection.route,'nearest route projection missing');
assert(routeProjection.crossTrackDistance>=0,'route projection distance invalid');

const discoveredRouteState=nav.createState({
  x:12,
  y:19,
  discoveredRoutes:['rootline-west']
});
const routeContext=nav.routeContext(discoveredRouteState);
assert(routeContext.route,'route context missing');
assert.strictEqual(typeof routeContext.progress,'number');
assert(routeContext.progress>=0 && routeContext.progress<=1,'route progress must stay normalized');

const sheltered=nav.travelProfile(discoveredRouteState);
assert.strictEqual(typeof sheltered.effectiveSpeed,'number');
assert.strictEqual(typeof sheltered.encounterPressure,'number');

const exposed=nav.travelProfile(stormState);
assert(exposed.encounterPressure>sheltered.encounterPressure,'hazardous weather should raise encounter pressure');
assert(exposed.effectiveSpeed<stormState.speed,'hazardous weather should reduce effective travel speed');

const squallMove=nav.move(stormState,1,0);
assert(squallMove.x-stormState.x<stormState.speed,'squall movement should be slower than nominal speed');
assert(squallMove.encounterSteps>1,'squall movement should accumulate additional encounter pressure');


const approach=nav.approachStatus(nav.createState({x:15,y:15,speed:3}));
assert(approach.active && approach.landmark.id==='verdant-crown','dockable landmark approach not detected');
assert.strictEqual(approach.speedLimit,1,'near-berth approach should impose a speed limit');
const approachProfile=nav.travelProfile(nav.createState({x:15,y:15,speed:3}));
assert(approachProfile.effectiveSpeed<=1,'approach envelope must limit effective speed');
const distantApproach=nav.approachStatus(nav.createState({x:0,y:0}));
assert.strictEqual(distantApproach.active,false,'distant landmarks should not activate approach state');

const nearest=nav.nearestLandmark(initial);
assert(nearest && nearest.landmark.id==='wake-dock');

assert(nav.SKY_ENCOUNTERS.some(e=>e.id==='skyPredator'),'sky encounter table missing');
assert(nav.ENCOUNTER_STEP_THRESHOLD>=5,'encounter cadence too dense');

let encounterState=nav.createState({x:12,y:12,encounterSteps:nav.ENCOUNTER_STEP_THRESHOLD});
const check=nav.encounterCheck(encounterState);
assert.strictEqual(typeof check.triggered,'boolean');
assert.strictEqual(check.state.encounterSteps,0,'encounter check must reset movement cadence');
assert.strictEqual(typeof check.threshold,'number','dynamic encounter threshold missing');
assert.strictEqual(typeof check.pressure,'number','encounter pressure telemetry missing');
assert(check.enemyId===null || ['skyPredator','windShear','aetherLeak'].includes(check.enemyId),'unknown sky enemy emitted');


const persisted=nav.exportPersistentState(nav.createState({
  x:17,y:15,altitude:'high',speed:2,
  discovered:['wake-dock','verdant-crown'],
  discoveredRoutes:['rootline-west'],
  encounterSteps:4,encounterSeed:3
}));
assert.strictEqual(persisted.version,nav.PERSISTENCE_VERSION,'navigation persistence version missing');
assert(nav.validatePersistentState(persisted),'valid navigation persistence rejected');
const restored=nav.restorePersistentState(persisted);
assert.strictEqual(restored.x,17);
assert.strictEqual(restored.altitude,'high');
assert.deepStrictEqual(restored.discoveredRoutes,['rootline-west']);
assert.strictEqual(restored.weatherId,nav.weatherAt(restored).id,'restored weather must be recomputed from geography');
assert.throws(
  ()=>nav.validatePersistentState(Object.assign({},persisted,{discoveredRoutes:['unknown-route']})),
  /AIR_NAV_STATE_ROUTE_DISCOVERY_INVALID/,
  'unknown persisted routes must fail closed'
);

const edge=nav.move(nav.createState({x:47,y:31,speed:3,encounterSteps:2}),1,1);
assert.strictEqual(edge.x,47);
assert.strictEqual(edge.y,31);
assert.strictEqual(edge.encounterSteps,2,'blocked boundary input must not advance encounter cadence');

const invalidMove=nav.move(initial,NaN,0);
assert(Number.isFinite(invalidMove.x) && Number.isFinite(invalidMove.y));
assert.strictEqual(invalidMove.encounterSteps,initial.encounterSteps,'invalid movement must fail closed');
const invalidAltitude=nav.changeAltitude(initial,Infinity);
assert.strictEqual(invalidAltitude.altitude,initial.altitude,'invalid altitude input must fail closed');

const validMoored=nav.exportPersistentState(docked);
assert(nav.validatePersistentState(validMoored),'valid moored state rejected');
assert.throws(
  ()=>nav.validatePersistentState(Object.assign({},validMoored,{speed:2})),
  /AIR_NAV_STATE_MOORING_INVALID/,
  'moving speed must not coexist with persisted mooring'
);
assert.throws(
  ()=>nav.validatePersistentState(Object.assign({},validMoored,{x:0,y:0})),
  /AIR_NAV_STATE_MOORING_INVALID/,
  'persisted mooring must be geometrically at the berth'
);

console.log('Aetherwake air navigation foundation: PASS');
