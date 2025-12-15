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

router.post('/airlines', async (req, res) => {
  try {
    const pool = await getPool();
    const name = (req.body?.name ?? '').toString();
    const country = (req.body?.country ?? '').toString();
    const contact = (req.body?.contact ?? '').toString();
    const request = pool.request();
    request.input('Name', sql.NVarChar(100), name);
    request.input('Country', sql.NVarChar(100), country);
    request.input('Contact', sql.NVarChar(50), contact);
    const result = await request.execute('FlightReservationSystem.usp_AddAirline');
    const row = (result.recordset && result.recordset[0]) || {};
    const data = {
      airlineId: parseInt(row.AirlineID ?? row.airlineId ?? 0) || 0,
      name: row.Name ?? row.name ?? name,
      country: row.Country ?? row.country ?? country,
      contact: row.Contact ?? row.contact ?? contact,
    };
    return res.status(200).json({ success: true, data });
  } catch (err) {
    console.error('Admin add airline error:', err);
    return res.status(500).json({ success: false, message: 'Failed to add airline.' });
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

router.delete('/airlines/:id', async (req, res) => {
  try {
    const pool = await getPool();
    const idRaw = req.params.id;
    const airlineId = parseInt(idRaw);
    const request = pool.request();
    request.input('AirlineID', sql.Int, airlineId);
    await request.execute('FlightReservationSystem.usp_DeleteAirlineCascade');
    return res.status(200).json({ success: true, data: { airlineId } });
  } catch (err) {
    console.error('Admin delete airline error:', err);
    return res.status(500).json({ success: false, message: 'Failed to delete airline.' });
  }
});

router.get('/airports', async (req, res) => {
  try {
    const pool = await getPool();
    const status = 'Active';
    let result;
    try {
      const request = pool.request();
      request.input('Status', sql.NVarChar(20), status);
      result = await request.execute('FlightReservationSystem.usp_GetAirports');
    } catch (e) {
      result = await pool.request().execute('FlightReservationSystem.usp_GetAirports');
    }
    const records = result.recordset || [];
    const rows = records
      .filter((row) => {
        const statusRaw = row.Status ?? row.status ?? row.AirportStatus ?? row.State ?? null;
        const status = typeof statusRaw === 'string' ? statusRaw.trim().toLowerCase() : null;
        return status === 'active';
      })
      .map((row) => ({
      airportId: parseInt(row.AirportID ?? row.airportId ?? 0) || 0,
      name: row.Name ?? row.name ?? '',
      city: row.City ?? row.city ?? '',
      country: row.Country ?? row.country ?? '',
      iataCode: row.IATA_Code ?? row.iataCode ?? row.IATA ?? '',
    }));
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    console.error('Admin airports error:', err);
    return res.status(500).json({ success: false, message: 'Failed to fetch airports.' });
  }
});

router.delete('/airports/:id', async (req, res) => {
  try {
    const pool = await getPool();
    const idRaw = req.params.id;
    const airportId = parseInt(idRaw);
    const request = pool.request();
    request.input('AirportID', sql.Int, airportId);
    await request.execute('FlightReservationSystem.usp_CloseAirport');
    return res.status(200).json({ success: true, data: { airportId } });
  } catch (err) {
    console.error('Admin close airport error:', err);
    return res.status(500).json({ success: false, message: 'Failed to close airport.' });
  }
});

router.put('/airports/:id', async (req, res) => {
  try {
    const pool = await getPool();
    const idRaw = req.params.id;
    const airportId = parseInt(idRaw);
    const name = (req.body?.name ?? '').toString();
    const city = (req.body?.city ?? '').toString();
    const country = (req.body?.country ?? '').toString();
    const iataCode = (req.body?.iataCode ?? '').toString();
    const request = pool.request();
    request.input('AirportID', sql.Int, airportId);
    request.input('Name', sql.NVarChar(100), name);
    request.input('City', sql.NVarChar(100), city);
    request.input('Country', sql.NVarChar(100), country);
    request.input('IATA_Code', sql.NVarChar(3), iataCode);
    const result = await request.execute('FlightReservationSystem.usp_UpdateAirport');
    const row = (result.recordset && result.recordset[0]) || {};
    const data = {
      airportId: parseInt(row.AirportID ?? airportId) || airportId,
      name: row.Name ?? name,
      city: row.City ?? city,
      country: row.Country ?? country,
      iataCode: row.IATA_Code ?? iataCode,
    };
    return res.status(200).json({ success: true, data });
  } catch (err) {
    console.error('Admin update airport error:', err);
    return res.status(500).json({ success: false, message: 'Failed to update airport.' });
  }
});

router.post('/airports', async (req, res) => {
  try {
    const pool = await getPool();
    const name = (req.body?.name ?? '').toString();
    const city = (req.body?.city ?? '').toString();
    const country = (req.body?.country ?? '').toString();
    const iataCode = (req.body?.iataCode ?? '').toString();
    const request = pool.request();
    request.input('Name', sql.NVarChar(100), name);
    request.input('City', sql.NVarChar(100), city);
    request.input('Country', sql.NVarChar(100), country);
    request.input('IATA_Code', sql.NVarChar(3), iataCode);
    const result = await request.execute('FlightReservationSystem.usp_AddAirport');
    const row = (result.recordset && result.recordset[0]) || {};
    const data = {
      airportId: parseInt(row.AirportID ?? row.airportId ?? 0) || 0,
      name: row.Name ?? name,
      city: row.City ?? city,
      country: row.Country ?? country,
      iataCode: row.IATA_Code ?? iataCode,
    };
    return res.status(200).json({ success: true, data });
  } catch (err) {
    console.error('Admin add airport error:', err);
    return res.status(500).json({ success: false, message: 'Failed to add airport.' });
  }
});
