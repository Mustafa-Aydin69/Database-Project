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
