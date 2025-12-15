require('dotenv').config();
const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth');
const checkinRoutes = require('./routes/checkin');
const parkingRoutes = require('./routes/parking');
const adminFlightMgmtRoutes = require('./routes/admin_flight_management');
const { getPool, sql } = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl} -> ${res.statusCode} ${duration}ms`);
  });
  next();
});

// Routes
app.use('/api', authRoutes);
app.use('/api/checkin', checkinRoutes);
app.use('/api/parking', parkingRoutes);
app.use('/api/admin/flight-management', adminFlightMgmtRoutes);

// Flight Classes endpoint
app.get('/api/flight-classes', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().execute('FlightReservationSystem.usp_GetFlightClasses');
    const rows = (result.recordset || []).map((row) => ({
      classId: parseInt(row.ClassID ?? row.classId ?? 0) || 0,
      className: row.ClassName ?? row.className ?? '',
      description: row.Description ?? row.description ?? '',
    }));
    return res.status(200).json(rows);
  } catch (err) {
    console.error('Flight classes fetch error:', err);
    return res.status(500).json({ message: 'Failed to fetch flight classes' });
  }
});
app.get('/api/admin/airlines', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().execute('FlightReservationSystem.usp_GetAirlines');
    const rows = (result.recordset || []).map((row) => ({
      airlineId: parseInt(row.AirlineID ?? row.airlineId ?? 0) || 0,
      name: row.Name ?? row.AirlineName ?? row.airlineName ?? '',
    }));
    return res.status(200).json(rows);
  } catch (err) {
    console.error('Admin airlines fetch error:', err);
    return res.status(500).json({ message: 'Failed to fetch airlines' });
  }
});
app.get('/api/admin/airports', async (req, res) => {
  try {
    const pool = await getPool();
    const request = pool.request();
    const result = await request.execute('FlightReservationSystem.usp_GetAirports');
    return res.json(result.recordset || []);
  } catch (err) {
    const info = err?.originalError?.info;
    console.error('Admin airports fetch error:', {
      message: info?.message || err?.message,
      number: info?.number,
      state: info?.state,
      class: info?.class,
      lineNumber: info?.lineNumber,
      procedure: info?.procName || info?.procedure,
      code: err?.code,
      stack: err?.stack,
      preceding: err?.precedingErrors?.map((e) => e?.message),
    });
    return res.status(500).json({ message: 'Failed to fetch airports', error: String(err?.message || err) });
  }
});
app.get('/api/admin/aircrafts', async (req, res) => {
  try {
    const airlineIdRaw = req.query.airlineId;
    const airlineId = parseInt(airlineIdRaw);
    if (!Number.isInteger(airlineId) || airlineId <= 0) {
      return res.status(400).json({ message: 'Invalid airlineId' });
    }
    const pool = await getPool();
    const request = pool.request();
    request.input('AirlineID', sql.Int, airlineId);
    let result;
    try {
      result = await request.execute('FlightReservationSystem.usp_GetAircraftsByAirline');
    } catch (execErr) {
      try {
        const alt = await pool.request().execute('FlightReservationSystem.usp_GetAircrafts');
        const all = alt.recordset || [];
        const filtered = all.filter((row) => {
          const aidRaw = row.AirlineID ?? row.airlineId ?? null;
          const aid = aidRaw === null || aidRaw === undefined ? null : parseInt(aidRaw);
          const statusRaw = row.Status ?? row.status ?? null;
          const status = typeof statusRaw === 'string' ? statusRaw.trim().toLowerCase() : null;
          return aid === airlineId && (status === null || status === 'active');
        });
        result = { recordset: filtered };
      } catch (queryErr) {
        const info = queryErr?.originalError?.info;
        console.error('Admin aircrafts fallback query error:', {
          message: info?.message || queryErr?.message,
          number: info?.number,
          code: queryErr?.code,
          stack: queryErr?.stack,
        });
        return res.status(500).json({ message: 'Failed to fetch aircrafts' });
      }
    }
    const rows = (result.recordset || []).map((row) => ({
      aircraftId: parseInt(row.AircraftID ?? row.aircraftId ?? 0) || 0,
      model: row.Model ?? row.model ?? '',
      capacity: parseInt(row.Capacity ?? row.capacity ?? 0) || 0,
    }));
    return res.status(200).json(rows);
  } catch (err) {
    const info = err?.originalError?.info;
    console.error('Admin aircrafts by airline fetch error:', {
      message: info?.message || err?.message,
      number: info?.number,
      code: err?.code,
      stack: err?.stack,
    });
    return res.status(500).json({ message: 'Failed to fetch aircrafts' });
  }
});

app.put('/api/flight-classes/:classId', async (req, res) => {
  try {
    console.log('PUT /api/flight-classes/:classId hit', { params: req.params, body: req.body });
    const idRaw = req.params.classId;
    const classId = parseInt(idRaw);
    if (!Number.isInteger(classId)) {
      return res.status(400).json({ message: 'Invalid classId' });
    }
    const rawName = (req.body?.className ?? '').toString().trim();
    const rawDesc = (req.body?.description ?? '').toString();
    if (!rawName) {
      return res.status(400).json({ message: 'ClassName cannot be empty' });
    }
    const pool = await getPool();
    const request = pool.request();
    request.input('ClassID', sql.Int, classId);
    request.input('ClassName', sql.NVarChar(100), rawName);
    const descToSend = rawDesc.trim().length === 0 ? null : rawDesc;
    request.input('Description', sql.NVarChar(255), descToSend);
    const result = await request.execute('FlightReservationSystem.usp_UpdateFlightClass');
    const row = (result.recordset && result.recordset[0]) || null;
    if (!row) {
      return res.status(404).json({ message: 'Flight class not found' });
    }
    const data = {
      classId: parseInt(row.ClassID ?? classId) || classId,
      className: row.ClassName ?? rawName,
      description: row.Description ?? '',
    };
    return res.status(200).json(data);
  } catch (err) {
    console.error('PUT /api/flight-classes error:', err);
    const info = err?.originalError?.info;
    const msg =
      info?.message ||
      (err?.precedingErrors && err.precedingErrors[0]?.message) ||
      err?.message ||
      'Failed to update flight class';
    const details = {
      code: err?.code,
      number: info?.number,
      state: info?.state,
      lineNumber: info?.lineNumber,
      serverName: info?.serverName,
      procName: info?.procName,
      stack: err?.stack,
    };
    if (/duplicate|unique|ClassName/i.test(msg)) {
      return res.status(400).json({ message: msg, details });
    }
    if (/not found|does not exist/i.test(msg)) {
      return res.status(404).json({ message: msg, details });
    }
    return res.status(500).json({ message: 'Failed to update flight class', details });
  }
});

app.post('/api/flight-classes', async (req, res) => {
  try {
    console.log('POST /api/flight-classes hit', { body: req.body });
    const rawName = (req.body?.className ?? '').toString().trim();
    const rawDesc = (req.body?.description ?? '').toString();
    if (!rawName) {
      return res.status(400).json({ message: 'ClassName cannot be empty' });
    }
    const pool = await getPool();
    const request = pool.request();
    request.input('ClassName', sql.NVarChar(100), rawName);
    const descToSend = rawDesc.trim().length === 0 ? null : rawDesc;
    request.input('Description', sql.NVarChar(255), descToSend);
    const result = await request.execute('FlightReservationSystem.usp_AddFlightClass');
    const row = (result.recordset && result.recordset[0]) || null;
    if (!row) {
      return res.status(500).json({ message: 'Failed to create flight class' });
    }
    const data = {
      classId: parseInt(row.ClassID ?? row.classId ?? 0) || 0,
      className: row.ClassName ?? rawName,
      description: row.Description ?? '',
    };
    return res.status(200).json(data);
  } catch (err) {
    console.error('POST /api/flight-classes error:', err);
    const info = err?.originalError?.info;
    const msg =
      info?.message ||
      (err?.precedingErrors && err.precedingErrors[0]?.message) ||
      err?.message ||
      'Failed to create flight class';
    const details = {
      code: err?.code,
      number: info?.number,
      state: info?.state,
      lineNumber: info?.lineNumber,
      serverName: info?.serverName,
      procName: info?.procName,
      stack: err?.stack,
    };
    if (/duplicate|unique|ClassName/i.test(msg)) {
      return res.status(400).json({ message: msg, details });
    }
    return res.status(500).json({ message: 'Failed to create flight class', details });
  }
});

console.log('Registered API routes:');
console.log('- GET  /api/flight-classes');
console.log('- POST /api/flight-classes');
console.log('- PUT  /api/flight-classes/:classId');

(async () => {
  try {
    const pool = await getPool();
    const result = await pool.request().query('SELECT TOP 1 * FROM GeneralCommon.ActivityLog');
    const sample = (result.recordset && result.recordset[0]) || {};
    console.log('ActivityLog check OK, sample columns:', Object.keys(sample).join(','));
  } catch (e) {
    const info = e?.originalError?.info;
    console.error('ActivityLog check failed:', {
      message: info?.message || e?.message,
      number: info?.number,
      code: e?.code,
      stack: e?.stack,
    });
  }
})();

// Aircrafts endpoint
app.get('/api/aircrafts', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().execute('FlightReservationSystem.usp_GetAircrafts');
    const rows = (result.recordset || [])
      .filter((row) => {
        const statusRaw = row.Status ?? row.status ?? null;
        const status = typeof statusRaw === 'string' ? statusRaw.trim().toLowerCase() : null;
        return status === null || status === 'active';
      })
      .map((row) => ({
        aircraftId: parseInt(row.AircraftID ?? row.aircraftId ?? 0) || 0,
        airlineId: row.AirlineID === null || row.AirlineID === undefined ? null : parseInt(row.AirlineID ?? row.airlineId),
        model: row.Model ?? row.model ?? '',
        capacity: parseInt(row.Capacity ?? row.capacity ?? 0) || 0,
        status: (row.Status ?? row.status ?? 'Active'),
      }));
    return res.status(200).json(rows);
  } catch (err) {
    console.error('Aircrafts fetch error:', err);
    return res.status(500).json({ message: 'Failed to fetch aircrafts' });
  }
});

app.patch('/api/aircrafts/:aircraftId/soft-delete', async (req, res) => {
  try {
    const idRaw = req.params.aircraftId;
    const aircraftId = parseInt(idRaw);
    if (!Number.isInteger(aircraftId) || aircraftId <= 0) {
      return res.status(400).json({ message: 'Invalid aircraftId' });
    }
    const pool = await getPool();
    const request = pool.request();
    request.input('AircraftID', sql.Int, aircraftId);
    const result = await request.execute('FlightReservationSystem.usp_SoftDeleteAircraft');
    const row = (result.recordset && result.recordset[0]) || null;
    if (!row) {
      return res.status(400).json({ message: 'Aircraft not found or already inactive' });
    }
    const data = {
      aircraftId: parseInt(row.AircraftID ?? aircraftId) || aircraftId,
      airlineId: row.AirlineID === null || row.AirlineID === undefined ? null : parseInt(row.AirlineID ?? row.airlineId),
      model: row.Model ?? '',
      capacity: parseInt(row.Capacity ?? 0) || 0,
      status: row.Status ?? 'Inactive',
    };
    return res.status(200).json(data);
  } catch (err) {
    console.error('PATCH /api/aircrafts/:aircraftId/soft-delete error:', err);
    const info = err?.originalError?.info;
    const msg =
      info?.message ||
      (err?.precedingErrors && err.precedingErrors[0]?.message) ||
      err?.message ||
      'Failed to delete aircraft';
    if (/not found|already inactive|does not exist/i.test(msg)) {
      return res.status(400).json({ message: msg });
    }
    return res.status(500).json({ message: 'Failed to delete aircraft' });
  }
});
app.get('/api/airlines', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().execute('FlightReservationSystem.usp_GetAirlines');
    const rows = (result.recordset || []).map((row) => ({
      airlineId: parseInt(row.AirlineID ?? row.airlineId ?? 0) || 0,
      airlineName: row.AirlineName ?? row.Name ?? row.airlineName ?? '',
    }));
    return res.status(200).json(rows);
  } catch (err) {
    console.error('Airlines fetch error:', err);
    return res.status(500).json({ message: 'Failed to fetch airlines' });
  }
});
app.get('/api/admin/flights', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().execute('FlightReservationSystem.usp_GetFlights_Simple');
    const rows = (result.recordset || []).map((row) => {
      const sRaw = row.Status ?? row.status ?? '';
      const sLower = typeof sRaw === 'string' ? sRaw.trim().toLowerCase() : '';
      const status =
        sLower === 'cancelled' || sLower === 'canceled' ? 'Canceled' :
        (typeof sRaw === 'string' ? sRaw : '');
      return {
        flightID: parseInt(row.FlightID ?? row.flightId ?? 0) || 0,
        airline: row.AirlineName ?? row.airlineName ?? '',
        aircraft: row.AircraftModel ?? row.aircraftModel ?? '',
        departureAirport: row.DepartureIATA ?? row.departureIata ?? '',
        arrivalAirport: row.ArrivalIATA ?? row.arrivalIata ?? '',
        departureTime: row.DepartureTime ?? row.departureTime ?? '',
        arrivalTime: row.ArrivalTime ?? row.arrivalTime ?? '',
        status,
      };
    });
    return res.status(200).json(rows);
  } catch (err) {
    console.error('Admin flights fetch error:', err);
    return res.status(500).json({ message: 'Failed to fetch flights' });
  }
});

app.post('/api/admin/flights', async (req, res) => {
  try {
    const airlineId = parseInt(req.body?.airlineId);
    const aircraftId = parseInt(req.body?.aircraftId);
    const departureAirportId = parseInt(req.body?.departureAirportId);
    const arrivalAirportId = parseInt(req.body?.arrivalAirportId);
    const departureTimeStr = (req.body?.departureTime ?? '').toString().trim();
    const arrivalTimeStr = (req.body?.arrivalTime ?? '').toString().trim();
    let status = (req.body?.status ?? '').toString().trim();
    const normalize = (s) => {
      const t = s.toLowerCase();
      if (t === 'cancelled' || t === 'canceled') return 'Canceled';
      if (t === 'scheduled') return 'Scheduled';
      if (t === 'delayed') return 'Delayed';
      if (t === 'completed') return 'Completed';
      return s;
    };
    status = normalize(status);
    if (!Number.isInteger(airlineId) || airlineId <= 0) {
      return res.status(400).json({ message: 'Invalid airlineId' });
    }
    if (!Number.isInteger(aircraftId) || aircraftId <= 0) {
      return res.status(400).json({ message: 'Invalid aircraftId' });
    }
    if (!Number.isInteger(departureAirportId) || departureAirportId <= 0) {
      return res.status(400).json({ message: 'Invalid departureAirportId' });
    }
    if (!Number.isInteger(arrivalAirportId) || arrivalAirportId <= 0) {
      return res.status(400).json({ message: 'Invalid arrivalAirportId' });
    }
    if (departureAirportId === arrivalAirportId) {
      return res.status(400).json({ message: 'Departure and arrival airports must be different' });
    }
    if (!departureTimeStr || !arrivalTimeStr) {
      return res.status(400).json({ message: 'DepartureTime and ArrivalTime are required' });
    }
    const dep = new Date(departureTimeStr.replace(' ', 'T'));
    const arr = new Date(arrivalTimeStr.replace(' ', 'T'));
    if (!(dep instanceof Date) || isNaN(dep.valueOf())) {
      return res.status(400).json({ message: 'Invalid departureTime' });
    }
    if (!(arr instanceof Date) || isNaN(arr.valueOf())) {
      return res.status(400).json({ message: 'Invalid arrivalTime' });
    }
    if (arr.valueOf() <= dep.valueOf()) {
      return res.status(400).json({ message: 'ArrivalTime must be after DepartureTime' });
    }
    const pool = await getPool();
    const request = pool.request();
    request.input('AirlineID', sql.Int, airlineId);
    request.input('AircraftID', sql.Int, aircraftId);
    request.input('DepartureAirportID', sql.Int, departureAirportId);
    request.input('ArrivalAirportID', sql.Int, arrivalAirportId);
    request.input('DepartureTime', sql.DateTime, dep);
    request.input('ArrivalTime', sql.DateTime, arr);
    request.input('Status', sql.NVarChar(20), status);
    const result = await request.execute('FlightReservationSystem.usp_AddFlight');
    const row = (result.recordset && result.recordset[0]) || {};
    return res.status(201).json(row);
  } catch (err) {
    const info = err?.originalError?.info;
    console.error('Admin add flight error:', {
      message: info?.message || err?.message,
      number: info?.number,
      state: info?.state,
      class: info?.class,
      lineNumber: info?.lineNumber,
      procedure: info?.procName || info?.procedure,
      code: err?.code,
      stack: err?.stack,
      preceding: err?.precedingErrors?.map((e) => e?.message),
    });
    return res.status(500).json({ message: 'Failed to add flight' });
  }
});
app.post('/api/aircrafts', async (req, res) => {
  try {
    const airlineIdRaw = req.body?.airlineId;
    const model = (req.body?.model ?? '').toString().trim();
    const capacityRaw = req.body?.capacity;
    const airlineId = airlineIdRaw === null || airlineIdRaw === undefined ? null : parseInt(airlineIdRaw);
    const capacity = parseInt(capacityRaw);
    if (!model) {
      return res.status(400).json({ message: 'Model cannot be empty' });
    }
    if (!Number.isFinite(capacity) || capacity <= 0) {
      return res.status(400).json({ message: 'Capacity must be greater than 0' });
    }
    const pool = await getPool();
    const request = pool.request();
    if (airlineId !== null && airlineId !== undefined) {
      request.input('AirlineID', sql.Int, airlineId);
    } else {
      request.input('AirlineID', sql.Int, null);
    }
    request.input('Model', sql.NVarChar(100), model);
    request.input('Capacity', sql.Int, capacity);
    const result = await request.execute('FlightReservationSystem.usp_AddAircraft');
    const row = (result.recordset && result.recordset[0]) || {};
    const data = {
      aircraftId: parseInt(row.AircraftID ?? row.aircraftId ?? 0) || 0,
      airlineId: row.AirlineID === null || row.AirlineID === undefined ? null : parseInt(row.AirlineID ?? row.airlineId),
      model: row.Model ?? model,
      capacity: parseInt(row.Capacity ?? capacity) || capacity,
    };
    return res.status(200).json(data);
  } catch (err) {
    console.error('POST /api/aircrafts error:', err);
    const info = err?.originalError?.info;
    const msg =
      info?.message ||
      (err?.precedingErrors && err.precedingErrors[0]?.message) ||
      err?.message ||
      'Failed to create aircraft';
    if (/invalid airline|AirlineID/i.test(msg)) {
      return res.status(400).json({ message: msg });
    }
    if (/model cannot be empty|capacity/i.test(msg)) {
      return res.status(400).json({ message: msg });
    }
    if (/duplicate|already exists|AirlineID.*Model/i.test(msg)) {
      return res.status(500).json({ message: 'Failed to create aircraft' });
    }
    return res.status(500).json({ message: 'Failed to create aircraft' });
  }
});
app.delete('/api/flight-classes/:classId', async (req, res) => {
  try {
    const idRaw = req.params.classId;
    const classId = parseInt(idRaw);
    if (!Number.isInteger(classId)) {
      return res.status(400).json({ message: 'Invalid classId' });
    }
    if (classId === 1) {
      return res.status(400).json({ message: 'Default class (ClassID = 1) cannot be deleted.' });
    }
    const pool = await getPool();
    const request = pool.request();
    request.input('ClassID', sql.Int, classId);
    const result = await request.execute('FlightReservationSystem.usp_DeleteFlightClass_ReassignToDefault');
    const row = (result.recordset && result.recordset[0]) || null;
    if (!row) {
      return res.status(400).json({ message: 'Flight class not found or cannot be deleted.' });
    }
    const data = {
      deletedClassId: parseInt(row.DeletedClassID ?? row.deletedClassId ?? classId) || classId,
      deletedClassName: row.DeletedClassName ?? row.deletedClassName ?? '',
      reassignedToClassId: parseInt(row.ReassignedToClassID ?? row.reassignedToClassId ?? 1) || 1,
      seatsReassigned: parseInt(row.SeatsReassigned ?? row.seatsReassigned ?? 0) || 0,
      flightPricingReassigned: parseInt(row.FlightPricingReassigned ?? row.flightPricingReassigned ?? 0) || 0,
    };
    return res.status(200).json(data);
  } catch (err) {
    console.error('DELETE /api/flight-classes error:', err);
    const info = err?.originalError?.info;
    const msg =
      info?.message ||
      (err?.precedingErrors && err.precedingErrors[0]?.message) ||
      err?.message ||
      'Failed to delete flight class';
    const details = {
      code: err?.code,
      number: info?.number,
      state: info?.state,
      lineNumber: info?.lineNumber,
      serverName: info?.serverName,
      procName: info?.procName,
      stack: err?.stack,
    };
    if (/default class.*cannot be deleted|ClassID\s*=\s*1/i.test(msg)) {
      return res.status(400).json({ message: msg, details });
    }
    if (/not found|does not exist|cannot be deleted/i.test(msg)) {
      return res.status(400).json({ message: msg, details });
    }
    return res.status(500).json({ message: 'Failed to delete flight class', details });
  }
});
function logRoutes(app) {
  try {
    const routes = [];
    app._router.stack.forEach((middleware) => {
      if (middleware.route) {
        const path = middleware.route.path;
        const methods = Object.keys(middleware.route.methods)
          .filter((m) => middleware.route.methods[m])
          .map((m) => m.toUpperCase());
        methods.forEach((method) => routes.push(`${method} ${path}`));
      } else if (middleware.name === 'router' && middleware.handle.stack) {
        middleware.handle.stack.forEach((handler) => {
          const route = handler.route;
          if (route) {
            const path = route.path;
            const methods = Object.keys(route.methods)
              .filter((m) => route.methods[m])
              .map((m) => m.toUpperCase());
            methods.forEach((method) => routes.push(`${method} ${middleware.regexp?.source?.replace('^\\','/').replace('\\/?(?=\\/|$)','') || ''}${path}`));
          }
        });
      }
    });
    console.log('Registered routes:');
    routes.forEach((r) => console.log(`- ${r}`));
  } catch (e) {
    console.log('Route logging failed:', e?.message || e);
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Server is running' });
});

app.get('/api/parking/recent-checkouts', (req, res) => {
  res.json({ success: true, data: [] });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server is running on http://0.0.0.0:${PORT}`);
  console.log(`📡 API endpoints available at http://0.0.0.0:${PORT}/api`);
  logRoutes(app);
});
