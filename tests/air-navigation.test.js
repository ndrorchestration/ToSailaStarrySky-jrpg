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

const edge=nav.move(nav.createState({x:47,y:31,speed:3}),1,1);
assert.strictEqual(edge.x,47);
assert.strictEqual(edge.y,31);

console.log('Aetherwake air navigation foundation: PASS');
