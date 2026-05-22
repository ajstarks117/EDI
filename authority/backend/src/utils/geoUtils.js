'use strict';

const EARTH_RADIUS_KM = 6371;

/**
 * Haversine distance between two lat/lng points.
 * @param {number} lat1
 * @param {number} lng1
 * @param {number} lat2
 * @param {number} lng2
 * @returns {number} distance in kilometres
 */
const haversineDistance = (lat1, lng1, lat2, lng2) => {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_KM * c;
};

/**
 * Compute an axis-aligned bounding box around a centre point.
 * @param {number} lat          - centre latitude
 * @param {number} lng          - centre longitude
 * @param {number} radiusKm     - radius in km
 * @returns {{ minLat, maxLat, minLng, maxLng }}
 */
const getBoundingBox = (lat, lng, radiusKm) => {
  const latDelta = radiusKm / EARTH_RADIUS_KM * (180 / Math.PI);
  const lngDelta = latDelta / Math.cos((lat * Math.PI) / 180);
  return {
    minLat: lat - latDelta,
    maxLat: lat + latDelta,
    minLng: lng - lngDelta,
    maxLng: lng + lngDelta,
  };
};

/**
 * Point-in-polygon test using the ray-casting algorithm.
 * @param {{ lat: number, lng: number }} point
 * @param {Array<{ lat: number, lng: number }>} polygon
 * @returns {boolean}
 */
const pointInPolygon = (point, polygon) => {
  let inside = false;
  const { lat: py, lng: px } = point;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const { lat: iy, lng: ix } = polygon[i];
    const { lat: jy, lng: jx } = polygon[j];
    const intersect =
      iy > py !== jy > py && px < ((jx - ix) * (py - iy)) / (jy - iy) + ix;
    if (intersect) inside = !inside;
  }
  return inside;
};

module.exports = { haversineDistance, getBoundingBox, pointInPolygon };
