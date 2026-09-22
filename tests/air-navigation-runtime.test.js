'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path');
const runtime=fs.readFileSync(path.join(__dirname,'..','aetherwake.js'),'utf8');
const html=fs.readFileSync(path.join(__dirname,'..','index.html'),'utf8');
assert(html.includes('modules/air-navigation.js'),'air-navigation module not loaded');
assert(runtime.includes('function drawAirNavigationScene()'),'playable sky renderer missing');
assert(runtime.includes('function handleAirNavigationInput(input)'),'flight controls missing');
assert(runtime.includes('drawUnfinishedSongExterior(width / 2, height / 2, 0.9)'),'hero ship not rendered in flight');
assert(runtime.includes('nav.LANDMARKS'),'sky landmarks not projected');
assert(runtime.includes('nav.move(airNavigationState'),'flight movement not bound');
assert(runtime.includes('nav.changeAltitude(airNavigationState'),'altitude controls not bound');
assert(runtime.includes('airshipFlightMode = true'),'airship systems do not enter flight');
assert(runtime.includes('pageUp, pageDown, shift'),'flight control channels missing');
assert(runtime.includes('nav.SKY_ROUTES'),'sky route graph is not rendered');
assert(runtime.includes("weather.id === 'crosswind'"),'crosswind presentation missing');
assert(runtime.includes("weather.id === 'aether-squall'"),'aether-squall presentation missing');
assert(runtime.includes("keysPressed[68] && typeof nav.dock === 'function'"),'dock command not bound');
assert(runtime.includes("showToast('MOORED // '"),'docking feedback missing');
assert(runtime.includes("nav.undock(airNavigationState)"),'directional cast-off behavior missing');
assert(runtime.includes('BERTH AVAILABLE:'),'berth approach UI missing');
assert(runtime.includes("{ id: 'flight', label: 'OPEN-SKY FLIGHT' }"),'explicit flight command missing');
assert(runtime.includes("{ id: 'phaseSlip', label: 'PHASE-SLIP' }"),'phase-slip command was lost');
assert(runtime.includes("LANDING DENIED // DOCK AT A STABLE BERTH"),'midair disembark guard missing');
assert(!runtime.includes("if (input.cancel) { airshipFlightMode = false; leaveAirship(); }"),'flight cancel still permits direct midair world exit');
assert(runtime.includes("ENTER / ESC SYSTEMS"),'flight controls still advertise unsafe landing');
assert(runtime.indexOf('combatReturnState = returnState || STATE.WORLD;') >
       runtime.indexOf('combat.canBeginEncounter'),
  'combat return state is committed before invalid-enemy preflight');
console.log('Aetherwake playable air-navigation contract: PASS');
