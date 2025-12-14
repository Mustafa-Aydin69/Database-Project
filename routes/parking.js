const express = require('express');
const router = express.Router();
const { getPool } = require('../config/database');
console.log('Parking router loaded');

router.get('/recent-checkouts', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().execute('AirportParkingSystem.usp_GetRecentCheckOuts');

    const rows = (result.recordset || []).map((row) => {
      const plateNumber =
        row.PlateNumber ||
        row.plateNumber ||
        '';

      const durationRaw =
        row.DurationMinutes ??
        row.durationMinutes ??
        row.Duration ??
        row.duration ??
        0;
      const durationMinutes = parseInt(durationRaw) || 0;

      const timeRaw =
        row.CheckOutTime ??
        row.checkOutTime ??
        row.CheckOut_Date ??
        row.checkOutDate;
      let checkOutTime = null;
      if (timeRaw) {
        const date = timeRaw instanceof Date ? timeRaw : new Date(timeRaw);
        if (!isNaN(date.getTime())) {
          checkOutTime = date.toISOString().replace('Z', '');
        }
      }

      const amountRaw =
        row.Amount ??
        row.amount ??
        row.TotalAmount ??
        row.totalAmount;
      const amount =
        typeof amountRaw === 'number'
          ? amountRaw
          : parseFloat(amountRaw) || 0;

      return {
        plateNumber,
        durationMinutes,
        checkOutTime,
        amount,
      };
    });

    res.json({ success: true, data: rows });
  } catch (error) {
    console.error('Recent Check-outs error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: [],
    });
  }
});

// POST /api/parking/checkout
router.post('/checkout', async (req, res) => {
  try {
    const { getPool, sql } = require('../config/database');
    const body = req.body || {};

    const plateNumber = (body.plateNumber || '').toString().trim();
    const amount = body.amount;
    const paymentMethod = body.paymentMethod ? body.paymentMethod.toString().trim() : null;
    const actorUserId = body.actorUserId !== undefined ? parseInt(body.actorUserId) : null;

    if (!plateNumber) {
      return res.status(400).json({ success: false, message: 'PlateNumber gereklidir' });
    }
    if (amount === undefined || amount === null || isNaN(parseFloat(amount))) {
      return res.status(400).json({ success: false, message: 'Amount gereklidir' });
    }

    const pool = await getPool();
    const request = pool.request();
    request.input('PlateNumber', sql.VarChar(20), plateNumber);
    request.input('Amount', sql.Decimal(10, 2), parseFloat(amount));
    request.input('PaymentMethod', sql.VarChar(30), paymentMethod);
    request.input('ActorUserID', sql.Int, actorUserId);

    await request.execute('AirportParkingSystem.usp_CheckOutVehicle');

    return res.json({ success: true, data: [] });
  } catch (error) {
    console.error('Checkout error:', error);
    return res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

router.get('/kpi-cards', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().execute('AirportParkingSystem.usp_GetParkingKpiCards');

    const row = (result.recordset && result.recordset[0]) ? result.recordset[0] : {};

    const totalSpots = parseInt(
      row.TotalSpots ?? row.totalSpots ?? 0
    ) || 0;
    const occupiedSpots = parseInt(
      row.OccupiedSpots ?? row.occupiedSpots ?? 0
    ) || 0;
    const freeSpots = parseInt(
      row.FreeSpots ?? row.freeSpots ?? 0
    ) || 0;
    const activeReservations = parseInt(
      row.ActiveReservations ?? row.activeReservations ?? 0
    ) || 0;

    res.json({
      success: true,
      data: {
        totalSpots,
        occupiedSpots,
        freeSpots,
        activeReservations
      }
    });
  } catch (error) {
    console.error('KPI cards error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

router.get('/lot-occupancy', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().execute('AirportParkingSystem.usp_GetParkingLotOccupancy');

    const rows = (result.recordset || []).map(row => {
      const parkingLotName = row.ParkingLotName || row.parkingLotName || '';
      const totalSpots = parseInt(row.TotalSpots ?? row.totalSpots ?? 0) || 0;
      const occupiedSpots = parseInt(row.OccupiedSpots ?? row.occupiedSpots ?? 0) || 0;
      const freeSpots = parseInt(row.FreeSpots ?? row.freeSpots ?? 0) || 0;
      const occupancyRateRaw = row.OccupancyRate ?? row.occupancyRate ?? 0;
      const occupancyRate = typeof occupancyRateRaw === 'number'
        ? occupancyRateRaw
        : parseFloat(occupancyRateRaw) || 0;

      return {
        parkingLotName,
        totalSpots,
        occupiedSpots,
        freeSpots,
        occupancyRate
      };
    });

    res.json({ success: true, data: rows });
  } catch (error) {
    console.error('Lot occupancy error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

module.exports = router;
router.get('/recent-checkins', async (req, res) => {
  try {
    const db = require('../config/database');
    const sql = db.sql;

    let topN = 5;
    if (req.query && req.query.topN !== undefined) {
      const n = parseInt(req.query.topN);
      if (!isNaN(n)) {
        topN = Math.max(1, Math.min(50, n));
      }
    }

    const pool = await getPool();
    const request = pool.request();
    request.input('TopN', sql.Int, topN);
    const result = await request.execute('AirportParkingSystem.usp_GetRecentCheckIns');

    const rows = (result.recordset || []).map(row => {
      const plateNumber = row.PlateNumber || row.plateNumber || '';
      const vehicleType = row.VehicleType || row.vehicleType || '';
      const spot = row.Spot || row.SpotNumber || row.spotNumber || '';

      const timeRaw = row.CheckInTime || row.checkInTime;
      let checkInTime = null;
      if (timeRaw) {
        const date = timeRaw instanceof Date ? timeRaw : new Date(timeRaw);
        if (!isNaN(date.getTime())) {
          checkInTime = date.toISOString().replace('Z', '');
        }
      }

      return {
        plateNumber,
        vehicleType,
        checkInTime,
        spot
      };
    });

    res.json({ success: true, data: rows });
  } catch (error) {
    console.error('Recent Check-ins error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

// Yeni endpoint: recent-checkouts-v2 (TopN destekli)
router.get('/recent-checkouts-v2', async (req, res) => {
  try {
    const { getPool, sql } = require('../config/database');

    let topN = 5;
    if (req.query && req.query.topN !== undefined) {
      const n = parseInt(req.query.topN);
      if (!isNaN(n)) {
        topN = Math.max(1, Math.min(50, n));
      }
    }

    const pool = await getPool();
    const request = pool.request();
    request.input('TopN', sql.Int, topN);
    const result = await request.execute('AirportParkingSystem.usp_GetRecentCheckOuts');

    const rows = (result.recordset || []).map((row) => {
      const plateNumber =
        row.PlateNumber ||
        row.plateNumber ||
        '';

      const durationRaw =
        row.DurationMinutes ??
        row.durationMinutes ??
        row.Duration ??
        row.duration ??
        0;
      const durationMinutes = parseInt(durationRaw) || 0;

      const timeRaw =
        row.CheckOutTime ??
        row.checkOutTime ??
        row.CheckOut_Date ??
        row.checkOutDate;
      let checkOutTime = null;
      if (timeRaw) {
        const date = timeRaw instanceof Date ? timeRaw : new Date(timeRaw);
        if (!isNaN(date.getTime())) {
          checkOutTime = date.toISOString().replace('Z', '');
        }
      }

      const amountRaw =
        row.Amount ??
        row.amount ??
        row.TotalAmount ??
        row.totalAmount;
      const amount =
        typeof amountRaw === 'number'
          ? amountRaw
          : parseFloat(amountRaw) || 0;

      return {
        plateNumber,
        durationMinutes,
        checkOutTime,
        amount,
      };
    });

    res.json({ success: true, data: rows });
  } catch (error) {
    console.error('Recent Check-outs v2 error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

router.get('/currently-parked', async (req, res) => {
  try {
    const { getPool } = require('../config/database');
    const pool = await getPool();
    const result = await pool.request().execute('AirportParkingSystem.usp_GetCurrentlyParkedVehicles');

    const rows = (result.recordset || []).map(row => {
      const plateNumber = row.PlateNumber || row.plateNumber || '';
      const vehicleType = row.VehicleType || row.vehicleType || '';
      const ownerName = row.OwnerName || row.ownerName || '';
      const parkingLot = row.ParkingLot || row.parkingLot || '';
      const spotCode = row.SpotCode || row.spotCode || row.Spot || row.SpotNumber || '';

      const timeRaw = row.CheckInTime || row.checkInTime;
      let checkInTime = null;
      if (timeRaw) {
        const date = timeRaw instanceof Date ? timeRaw : new Date(timeRaw);
        if (!isNaN(date.getTime())) {
          checkInTime = date.toISOString().replace('Z', '');
        }
      }

      return {
        plateNumber,
        vehicleType,
        ownerName,
        checkInTime,
        parkingLot,
        spotCode
      };
    });

    res.json({ success: true, data: rows });
  } catch (error) {
    console.error('Currently parked error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

router.get('/exit-panel-cards', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().execute('AirportParkingSystem.usp_GetExitPanelCards');

    if (result.recordset && result.recordset[0]) {
      console.log(Object.keys(result.recordset[0]));
      console.log(result.recordset[0]);
    }
    return res.json({ success: true, data: result.recordset || [] });
  } catch (error) {
    console.error('Exit panel cards error:', error);
    return res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

// GET /api/parking/exit-popup-info?plateNumber=...
router.get('/exit-popup-info', async (req, res) => {
  try {
    const { getPool, sql } = require('../config/database');
    const plateNumber = (req.query?.plateNumber || '').toString().trim();
    if (!plateNumber) {
      return res.status(400).json({ success: false, message: 'plateNumber is required' });
    }
    const pool = await getPool();
    const request = pool.request();
    request.input('PlateNumber', sql.NVarChar, plateNumber);
    const result = await request.execute('AirportParkingSystem.usp_GetExitPopupInfo');
    const row = (result.recordset && result.recordset[0]) ? result.recordset[0] : null;
    if (!row) {
      return res.status(404).json({ success: false, message: 'Kayıt bulunamadı' });
    }
    const plate = row.PlateNumber ?? row.plateNumber ?? plateNumber;
    const ownerName = row.OwnerName ?? row.ownerName ?? '';
    const timeRaw = row.CheckInTime ?? row.checkInTime;
    let checkInTime = null;
    if (timeRaw) {
      const date = timeRaw instanceof Date ? timeRaw : new Date(timeRaw);
      if (!isNaN(date.getTime())) {
        checkInTime = date.toISOString();
      }
    }
    const durationRaw = row.DurationMinutes ?? row.durationMinutes ?? 0;
    const durationMinutes = typeof durationRaw === 'number' ? durationRaw : parseInt(durationRaw) || 0;
    const amountRaw = row.Amount ?? row.amount ?? 0;
    const amount = typeof amountRaw === 'number' ? amountRaw : parseFloat(amountRaw) || 0;
    return res.json({
      success: true,
      data: {
        plateNumber: plate,
        ownerName,
        checkInTime,
        durationMinutes,
        amount
      }
    });
  } catch (error) {
    console.error('Exit popup info error:', error);
    return res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});
