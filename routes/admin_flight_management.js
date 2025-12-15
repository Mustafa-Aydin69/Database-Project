const express = require('express');
const router = express.Router();
const { getPool, sql } = require('../config/database');

router.get('/airlines', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().execute('FlightReservationSystem.usp_GetAirlines');
    const rows = (result.recordset || []).map((row) => ({
      airlineId: parseInt(row.AirlineID ?? row.airlineId ?? 0) || 0,
      name: row.Name ?? row.name ?? '',
      country: row.Country ?? row.country ?? '',
      contact: row.Contact ?? row.contact ?? '',
    }));
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    console.error('Admin airlines error:', err);
    return res.status(500).json({ success: false, message: 'Failed to fetch airlines.' });
  }
});

module.exports = router;

// Update airline
router.put('/airlines/:id', async (req, res) => {
  try {
    const pool = await getPool();
    const idRaw = req.params.id;
    const airlineId = parseInt(idRaw);
    const name = (req.body?.name ?? '').toString();
    const country = (req.body?.country ?? '').toString();
    const contact = (req.body?.contact ?? '').toString();
    const request = pool.request();
    request.input('AirlineID', sql.Int, airlineId);
    request.input('Name', sql.NVarChar(100), name);
    request.input('Country', sql.NVarChar(100), country);
    request.input('Contact', sql.NVarChar(50), contact);
    const result = await request.execute('FlightReservationSystem.usp_UpdateAirline');
    const row = (result.recordset && result.recordset[0]) || {};
    const data = {
      airlineId: parseInt(row.AirlineID ?? airlineId) || airlineId,
      name: row.Name ?? name,
      country: row.Country ?? country,
      contact: row.Contact ?? contact,
    };
    return res.status(200).json({ success: true, data });
  } catch (err) {
    console.error('Admin update airline error:', err);
    return res.status(500).json({ success: false, message: 'Failed to update airline.' });
  }
});
