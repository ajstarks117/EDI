'use strict';

const bcrypt = require('bcrypt');
const { query, pool } = require('../config/db');

const seedDemo = async () => {
  try {
    console.log('[seed] Starting idempotent demo seed...');

    // 1. Authority
    const authHash = await bcrypt.hash('demo@SIH2025', 10);
    const authRes = await query(
      `INSERT INTO authorities (badge_id, password_hash, role)
       VALUES ('DEMO01', $1, 'officer')
       ON CONFLICT (badge_id) DO UPDATE SET password_hash = EXCLUDED.password_hash
       RETURNING id`,
      [authHash]
    );
    const authorityId = authRes.rows[0].id;

    // 2. Tourist
    const touristRes = await query(
      `INSERT INTO tourists (tourist_id, phone, full_name, nationality, id_document_type, id_number_hash, blood_group, is_active)
       VALUES ('IND-DEMO1-SH', '+910000000001', 'Raj Sharma', 'Indian', 'aadhaar', 'DEMO_HASH_XYZ', 'B+', true)
       ON CONFLICT (phone) DO UPDATE SET full_name = EXCLUDED.full_name
       RETURNING id`
    );
    const touristId = touristRes.rows[0].id;

    // 3. Geo-fence zones around Pune (approx 18.5204° N, 73.8567° E)
    // danger (red)
    const dangerGeom = `ST_GeomFromGeoJSON('{"type":"Polygon","coordinates":[[[73.8567,18.5204],[73.8567,18.5304],[73.8667,18.5304],[73.8667,18.5204],[73.8567,18.5204]]]}')`;
    // restricted (orange)
    const restrictedGeom = `ST_GeomFromGeoJSON('{"type":"Polygon","coordinates":[[[73.8400,18.5100],[73.8400,18.5200],[73.8500,18.5200],[73.8500,18.5100],[73.8400,18.5100]]]}')`;
    // safe (green)
    const safeGeom = `ST_GeomFromGeoJSON('{"type":"Polygon","coordinates":[[[73.8700,18.5100],[73.8700,18.5400],[73.8900,18.5400],[73.8900,18.5100],[73.8700,18.5100]]]}')`;

    // Ensure they don't continuously duplicate using name logic or truncating
    await query(`DELETE FROM geofence_zones WHERE name LIKE 'DEMO ZONE %'`);

    await query(`
      INSERT INTO geofence_zones (name, zone_type, geom, advisory_text, created_by)
      VALUES 
        ('DEMO ZONE Danger Area', 'warning', ${dangerGeom}, 'High risk area. Do not enter.', $1),
        ('DEMO ZONE Restricted Area', 'restricted', ${restrictedGeom}, 'Only authorized personnel.', $1),
        ('DEMO ZONE Safe Area', 'safe', ${safeGeom}, 'Official safe zone.', $1)
    `, [authorityId]);

    // 4. Seed SOS Alerts
    // One critical active, one resolved
    await query(`DELETE FROM sos_alerts WHERE source = 'test' AND channel = 'wifi_direct'`);
    
    await query(`
      INSERT INTO sos_alerts (tourist_id, lat, lng, source, channel, priority, status)
      VALUES 
        ($1, 18.5204, 73.8567, 'test', 'wifi_direct', 'critical', 'active'),
        ($1, 18.5304, 73.8467, 'test', 'wifi_direct', 'low', 'resolved')
    `, [touristId]);

    console.log('Demo seed complete. Authority: DEMO01 / demo@SIH2025');

  } catch (err) {
    console.error('[seed] Error seeding demo data:', err.message);
  } finally {
    pool.end();
  }
};

seedDemo();
