/*
 * To Sail the Starry Sky — illustrative planetary cartography palette.
 * This is NON-CANON sample geography shared by chart, flight and horizon.
 * Values are radians, and there is no game-world/save/schema dependency.
 * The material model is intentionally lightweight and deterministic.
 */
(function attach(root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.AetherPlanetaryCartography = factory();
}(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';
  const VERSION = '0.1.0-study';
  const DEG = Math.PI / 180;
  const TWO_PI = Math.PI * 2;
  const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
  const seam = (a, b) => Math.atan2(Math.sin(a - b), Math.cos(a - b));
  const elliptical = (lat, lon, cLat, cLon, dy, dx) =>
    Math.hypot((lat - cLat) / dy, seam(lon, cLon) / dx);
  function sample(latitudeRad, longitudeRad) {
    if (!Number.isFinite(latitudeRad) || !Number.isFinite(longitudeRad) ||
        Math.abs(latitudeRad) > Math.PI / 2 + 1e-10) {
      throw new RangeError('CARTOGRAPHY_INVALID_COORDINATES');
    }
    const lat = latitudeRad, lon = longitudeRad;
    const absLat = Math.abs(lat) / DEG;
    const n = Math.sin(lon * 3.4 + Math.sin(lat * 2.3)) * .12 +
      Math.sin(lat * 7.3 - lon * 4.1) * .065 +
      Math.sin(lat * 13 + lon * 8) * .034;
    const d = Math.min(
      elliptical(lat,lon,18*DEG,-117*DEG,65*DEG,39*DEG),
      elliptical(lat,lon,34*DEG,28*DEG,55*DEG,50*DEG),
      elliptical(lat,lon,-31*DEG,125*DEG,35*DEG,41*DEG),
      elliptical(lat,lon,69*DEG,143*DEG,24*DEG,55*DEG),
      elliptical(lat,lon,-12*DEG,-16*DEG,16*DEG,23*DEG)
    );
    const islandArc = Math.abs(lat) < 19*DEG &&
      Math.abs(seam(lon,81*DEG)) < 47*DEG &&
      Math.sin(lon*13+Math.sin(lat*8))*Math.sin(lat*15-lon*5) > .57;
    const coast = 1 - (d + n);
    const land = coast > 0 || islandArc;
    const moist = Math.sin(lon*7+Math.sin(lat*5))*.5 +
      Math.cos(lat*6-lon*4)*.5;
    const ridges = Math.pow(Math.abs(Math.sin(lon*24 + Math.sin(lat*5)*3) *
      Math.cos(lat*17-lon*8)), 4);
    const relief = clamp(coast*.6 + ridges*.34,0,1);
    const grain = Math.sin(lat*47+lon*31)*Math.cos(lat*29-lon*61);
    let color, biome;
    if (!land) {
      if(absLat>78 && Math.sin(lon*11+lat*9)>.10) {
        biome='Polar ice';color=[204,229,229];
      } else if(coast>-.13) {
        biome='Coastal shelf';color=[39,145,149];
      } else if(coast>-.4) {
        biome='Open sea';color=[21,93,126];
      } else {
        biome='Deep ocean';color=[11,52,91];
      }
    } else if(absLat>77) { biome='Ice field';color=[222,230,224]; }
    else if(relief>.54 && absLat>35) { biome='Alpine';color=[162,159,142]; }
    else if(absLat>65) { biome='Tundra';color=[137,161,141]; }
    else if(absLat>51) { biome='Boreal forest';color=[59,112,100]; }
    else if(absLat>35) {
      biome=moist<-.38?'Grassland':'Temperate forest';
      color=moist<-.38?[140,160,104]:[65,137,111];
    } else if(absLat>20) {
      biome=moist>.18?'Woodland':'Semi-arid';
      color=moist>.18?[85,145,100]:[191,158,104];
    } else if(moist<-.26) {
      biome='Savanna';color=[183,154,90];
    } else {
      biome='Rainforest';color=[48,132,102];
    }
    const shade = land
      ? clamp(.88 + relief*.28 + grain*.035, .74, 1.24)
      : clamp(.91 + grain*.018, .87, .97);
    return {
      land, biome, relief, coast,
      color: color.map(component=>Math.round(clamp(component*shade,0,255)))
    };
  }
  // Latitude/longitude chart grid; only the observer-facing hemisphere draws.
  function drawGraticule(ctx,cx,cy,radius,latDeg,lonDeg) {
    const p0=latDeg*DEG,l0=lonDeg*DEG;
    const project=(p,l)=>{
      const delta=l-l0;
      const forward=Math.sin(p)*Math.sin(p0)+Math.cos(p)*Math.cos(p0)*Math.cos(delta);
      if(forward<-1e-6)return null;
      return [
        cx+radius*Math.cos(p)*Math.sin(delta),
        cy-radius*(Math.sin(p)*Math.cos(p0)-Math.cos(p)*Math.sin(p0)*Math.cos(delta))
      ];
    };
    const trace=(points)=>{
      let started=false;ctx.beginPath();
      for(const [p,l] of points) {
        const q=project(p,l);
        if(!q){started=false;continue;}
        if(!started){ctx.moveTo(q[0],q[1]);started=true;}
        else ctx.lineTo(q[0],q[1]);
      }
      ctx.stroke();
    };
    ctx.save();
    ctx.strokeStyle='rgba(237,223,181,.16)';
    ctx.lineWidth=.9;
    for(let lat=-60;lat<=60;lat+=30){
      const pts=[];for(let step=0;step<=144;step++)pts.push([lat*DEG,-Math.PI+step*TWO_PI/144]);
      trace(pts);
    }
    for(let lon=-180;lon<180;lon+=30){
      const pts=[];for(let step=0;step<=90;step++)pts.push([(-90+step*2)*DEG,lon*DEG]);
      trace(pts);
    }
    ctx.restore();
  }
  return Object.freeze({ VERSION, sample, drawGraticule });
}));
