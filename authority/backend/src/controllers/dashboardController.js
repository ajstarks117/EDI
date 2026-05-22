'use strict';

const { error, success, notImplemented } = require('../utils/responseUtils');
const { query } = require('../config/db');

/**
 * GET /api/dashboard/stats
 */
const getStats = async (req, res, next) => {
  try {
    const [alertsRes, touristsRes, zonesRes, totalRes] = await Promise.all([
      query(`SELECT COUNT(*) as cnt FROM sos_alerts WHERE status='active'`),
      query(`SELECT COUNT(DISTINCT tourist_id) as cnt FROM gps_logs WHERE captured_at > NOW() - INTERVAL '2 hours'`),
      query(`SELECT COUNT(*) as cnt FROM geofence_zones WHERE zone_type='safe' AND is_active=true`),
      query(`SELECT COUNT(*) as cnt FROM tourists WHERE is_active=true`)
    ]);

    const active_alerts = parseInt(alertsRes.rows[0].cnt, 10);
    const active_tourists = parseInt(touristsRes.rows[0].cnt, 10);
    const safe_zones = parseInt(zonesRes.rows[0].cnt, 10);
    const total_tourists = parseInt(totalRes.rows[0].cnt, 10);

    const safety_rate = total_tourists > 0 ? ((total_tourists - active_alerts) / total_tourists) * 100 : 100;

    return success(res, {
      active_alerts,
      active_tourists,
      safe_zones,
      total_tourists,
      safety_rate
    });
  } catch (err) {
    return next(err);
  }
};

/**
 * GET /api/dashboard/analytics
 */
const getAnalytics = async (req, res, next) => {
  try {
    const [countsByDay, avgRes, peakHours] = await Promise.all([
      query(`
        SELECT DATE(created_at) as day, COUNT(*) as count 
        FROM tourists 
        WHERE created_at > NOW() - INTERVAL '30 days' 
        GROUP BY day ORDER BY day ASC
      `),
      query(`
        SELECT AVG(EXTRACT(EPOCH FROM (updated_at - created_at))/60) as avg_minutes
        FROM sos_alerts
        WHERE status = 'resolved'
      `),
      query(`
        SELECT EXTRACT(HOUR FROM created_at) as hour, COUNT(*) as count
        FROM sos_alerts
        GROUP BY hour ORDER BY hour ASC
      `)
    ]);

    const tourist_count_by_day = countsByDay.rows.map(r => ({
      day: r.day,
      count: parseInt(r.count, 10)
    }));
    const avg_resolution_minutes = parseFloat(avgRes.rows[0].avg_minutes || 0);
    const peak_hours = peakHours.rows.map(r => ({
      hour: parseInt(r.hour, 10),
      count: parseInt(r.count, 10)
    }));

    return success(res, {
      tourist_count_by_day,
      avg_resolution_minutes,
      peak_hours
    });
  } catch (err) {
    return next(err);
  }
};

module.exports = {
  getStats,
  getAnalytics,
  getActiveAlerts: notImplemented,
  getTouristDensity: notImplemented,
};
