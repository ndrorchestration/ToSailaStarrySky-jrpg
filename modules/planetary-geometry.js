/*
 * Aetherwake — isolated spherical world-geometry contract (prototype).
 * No engine, map art, ship runtime or save-schema dependency.
 * All positions are latitude/longitude DEGREES and altitude KILOMETRES;
 * callers must explicitly supply the planet radius in KILOMETRES.
 * Aetherwake's canonical radius/cartography have NOT been selected.
 */
(function attach(root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.AetherPlanetaryGeometry = factory();
}(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  const VERSION = '0.1.0-prototype';
  const DEG = Math.PI / 180;
  const RAD = 180 / Math.PI;
  const ANGLE_EPSILON = 1e-12;

  function finiteNumber(value, label) {
    if (!Number.isFinite(value)) throw new RangeError('GLOBE_' + label + '_NONFINITE');
    return value;
  }

  function radius(radiusKm) {
    if (!Number.isFinite(radiusKm) || radiusKm <= 0) {
      throw new RangeError('GLOBE_RADIUS_INVALID');
    }
    return radiusKm;
  }

  function normalizeLongitude(lonDeg) {
    finiteNumber(lonDeg, 'LONGITUDE');
    const wrapped = ((lonDeg % 360) + 540) % 360 - 180;
    return Object.is(wrapped, -0) ? 0 : wrapped;
  }

  // Reflect across either pole, rotating longitude by 180 degrees when needed.
  function normalizeLatLon(latDeg, lonDeg) {
    finiteNumber(latDeg, 'LATITUDE');
    finiteNumber(lonDeg, 'LONGITUDE');
    let lat = ((latDeg % 360) + 540) % 360 - 180;
    let lon = lonDeg;
    if (lat > 90) { lat = 180 - lat; lon += 180; }
    else if (lat < -90) { lat = -180 - lat; lon += 180; }
    return {latDeg: Object.is(lat, -0) ? 0 : lat, lonDeg: normalizeLongitude(lon)};
  }

  function normalizePosition(point) {
    if (!point || typeof point !== 'object' || Array.isArray(point)) {
      throw new TypeError('GLOBE_POSITION_REQUIRED');
    }
    const coords = normalizeLatLon(point.latDeg, point.lonDeg);
    const altitudeKm = point.altitudeKm === undefined ? 0 : point.altitudeKm;
    finiteNumber(altitudeKm, 'ALTITUDE');
    if (altitudeKm < 0) throw new RangeError('GLOBE_ALTITUDE_NEGATIVE');
    return {...coords, altitudeKm};
  }

  function separationRad(a, b) {
    const p = normalizePosition(a), q = normalizePosition(b);
    const phi1 = p.latDeg * DEG, phi2 = q.latDeg * DEG;
    const dp = (q.latDeg - p.latDeg) * DEG;
    const dl = normalizeLongitude(q.lonDeg - p.lonDeg) * DEG;
    const h = Math.sin(dp / 2) ** 2 + Math.cos(phi1) * Math.cos(phi2) * Math.sin(dl / 2) ** 2;
    return 2 * Math.asin(Math.sqrt(Math.min(1, Math.max(0, h))));
  }

  function greatCircleDistanceKm(a, b, radiusKm) {
    return radius(radiusKm) * separationRad(a, b);
  }

  function initialBearingDeg(a, b) {
    const p = normalizePosition(a), q = normalizePosition(b);
    const phi1 = p.latDeg * DEG, phi2 = q.latDeg * DEG;
    const dl = normalizeLongitude(q.lonDeg - p.lonDeg) * DEG;
    const y = Math.sin(dl) * Math.cos(phi2);
    const x = Math.cos(phi1) * Math.sin(phi2) - Math.sin(phi1) * Math.cos(phi2) * Math.cos(dl);
    if (Math.hypot(x, y) < ANGLE_EPSILON) throw new RangeError('GLOBE_BEARING_UNDEFINED');
    return ((Math.atan2(y, x) * RAD) % 360 + 360) % 360;
  }

  function destinationPoint(start, bearingDeg, distanceKm, radiusKm) {
    const p = normalizePosition(start);
    finiteNumber(bearingDeg, 'BEARING');
    finiteNumber(distanceKm, 'DISTANCE');
    if (distanceKm < 0) throw new RangeError('GLOBE_DISTANCE_NEGATIVE');
    const angularDistance = distanceKm / radius(radiusKm);
    if (distanceKm === 0) return p;
    // Rotate in the local north/east tangent frame. Stable at the exact poles.
    const phi = p.latDeg * DEG, lambda = p.lonDeg * DEG, theta = bearingDeg * DEG;
    const c = Math.cos(phi), s = Math.sin(phi);
    const cx = Math.cos(lambda), sy = Math.sin(lambda);
    const alongNorth = Math.cos(theta) * Math.sin(angularDistance);
    const alongEast = Math.sin(theta) * Math.sin(angularDistance);
    const step = Math.cos(angularDistance);
    const x = c * cx * step - s * cx * alongNorth - sy * alongEast;
    const y = c * sy * step - s * sy * alongNorth + cx * alongEast;
    const z = s * step + c * alongNorth;
    return {...normalizeLatLon(Math.atan2(z, Math.hypot(x, y)) * RAD, Math.atan2(y, x) * RAD), altitudeKm: p.altitudeKm};
  }

  function horizonAngleRad(altitudeKm, radiusKm) {
    finiteNumber(altitudeKm, 'ALTITUDE');
    if (altitudeKm < 0) throw new RangeError('GLOBE_ALTITUDE_NEGATIVE');
    const r = radius(radiusKm);
    return Math.acos(r / (r + altitudeKm));
  }

  function horizonSurfaceDistanceKm(altitudeKm, radiusKm) {
    return radius(radiusKm) * horizonAngleRad(altitudeKm, radiusKm);
  }

  // Geometric occlusion by a spherical sea-level planet. No terrain elevation,
  // weather, fog, atmospheric refraction or discovery/route rights included.
  function hasLineOfSight(observer, target, radiusKm) {
    const o = normalizePosition(observer), t = normalizePosition(target);
    const limit = horizonAngleRad(o.altitudeKm, radiusKm) + horizonAngleRad(t.altitudeKm, radiusKm);
    return separationRad(o, t) <= limit + ANGLE_EPSILON;
  }

  function toCartesian(point, radiusKm) {
    const p = normalizePosition(point);
    const radial = radius(radiusKm) + p.altitudeKm;
    const lat = p.latDeg * DEG, lon = p.lonDeg * DEG;
    return {
      xKm: radial * Math.cos(lat) * Math.cos(lon),
      yKm: radial * Math.cos(lat) * Math.sin(lon),
      zKm: radial * Math.sin(lat)
    };
  }

  function fromCartesian(vector, radiusKm) {
    if (!vector || typeof vector !== 'object' || Array.isArray(vector)) throw new TypeError('GLOBE_VECTOR_REQUIRED');
    const x = finiteNumber(vector.xKm, 'X'), y = finiteNumber(vector.yKm, 'Y'), z = finiteNumber(vector.zKm, 'Z');
    const r = radius(radiusKm);
    const distanceFromCenter = Math.hypot(x, y, z);
    if (distanceFromCenter < r - r * 1e-12) throw new RangeError('GLOBE_INSIDE_PLANET');
    return {
      ...normalizeLatLon(Math.atan2(z, Math.hypot(x, y)) * RAD, Math.atan2(y, x) * RAD),
      altitudeKm: Math.max(0, distanceFromCenter - r)
    };
  }

  // Local east/north map coordinates around one chosen anchor. Restrict to
  // near hemisphere, so a region map cannot silently represent a whole world.
  function toLocalKm(anchor, target, radiusKm) {
    const r = radius(radiusKm);
    const arc = separationRad(anchor, target);
    if (arc >= Math.PI / 2 - ANGLE_EPSILON) throw new RangeError('GLOBE_LOCAL_RANGE_EXCEEDED');
    if (arc <= ANGLE_EPSILON) return {eastKm: 0, northKm: 0};
    const theta = initialBearingDeg(anchor, target) * DEG;
    const distance = r * arc;
    return {eastKm: distance * Math.sin(theta), northKm: distance * Math.cos(theta)};
  }

  function fromLocalKm(anchor, eastKm, northKm, radiusKm) {
    finiteNumber(eastKm, 'EAST');
    finiteNumber(northKm, 'NORTH');
    const r = radius(radiusKm);
    const distance = Math.hypot(eastKm, northKm);
    if (distance >= r * (Math.PI / 2 - ANGLE_EPSILON)) throw new RangeError('GLOBE_LOCAL_RANGE_EXCEEDED');
    if (distance === 0) return normalizePosition(anchor);
    const bearing = Math.atan2(eastKm, northKm) * RAD;
    return destinationPoint(anchor, bearing, distance, r);
  }

  return Object.freeze({
    VERSION,
    normalizeLongitude, normalizeLatLon, normalizePosition,
    separationRad, greatCircleDistanceKm, initialBearingDeg, destinationPoint,
    horizonAngleRad, horizonSurfaceDistanceKm, hasLineOfSight,
    toCartesian, fromCartesian, toLocalKm, fromLocalKm
  });
}));
