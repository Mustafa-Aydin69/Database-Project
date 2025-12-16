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

router.get('/parking-lots/:parkingLotId/detail', async (req, res) => {
  try {
    const db = require('../config/database');
    const getPool = db.getPool;
    const sql = db.sql;
    const idRaw = req.params.parkingLotId;
    const parkingLotId = parseInt(idRaw);
    if (isNaN(parkingLotId) || parkingLotId <= 0) {
      return res.status(400).json({ success: false, message: 'Geçersiz ParkingLotID' });
    }
    const pool = await getPool();
    const request = pool.request();
    request.input('ParkingLotID', sql.Int, parkingLotId);
    const result = await request.execute('AirportParkingSystem.usp_GetParkingLotDetail');
    const sets = result.recordsets || [];
    const summarySet = sets[0] || [];
    const terminalSet = sets[1] || [];
    const spotSet = sets[2] || [];
    if (!summarySet[0] || spotSet.length === 0) {
      return res.status(404).json({ success: false, message: 'Kayıt bulunamadı' });
    }
    const s = summarySet[0];
    const summary = {
      parkingLotId: s.ParkingLotID ?? s.parkingLotId ?? parkingLotId,
      lotName: s.LotName ?? s.lotName ?? '',
      totalSpots: parseInt(s.TotalSpots ?? s.totalSpots ?? 0) || 0,
      emptyCount: parseInt(s.EmptyCount ?? s.emptyCount ?? 0) || 0,
      occupiedCount: parseInt(s.OccupiedCount ?? s.occupiedCount ?? 0) || 0,
      reservedCount: parseInt(s.ReservedCount ?? s.reservedCount ?? 0) || 0,
      maintenanceCount: parseInt(s.MaintenanceCount ?? s.maintenanceCount ?? 0) || 0,
    };
    const terminals = terminalSet.map(t => ({
      terminalCode: t.TerminalCode ?? t.terminalCode ?? '',
      totalSpots: parseInt(t.TotalSpots ?? t.totalSpots ?? 0) || 0,
      emptyCount: parseInt(t.EmptyCount ?? t.emptyCount ?? 0) || 0,
      occupiedCount: parseInt(t.OccupiedCount ?? t.occupiedCount ?? 0) || 0,
      reservedCount: parseInt(t.ReservedCount ?? t.reservedCount ?? 0) || 0,
      maintenanceCount: parseInt(t.MaintenanceCount ?? t.maintenanceCount ?? 0) || 0,
    }));
    const spots = spotSet.map(sp => {
      const spotId = parseInt(sp.SpotID ?? sp.spotId ?? 0) || 0;
      const parkingLotIdNorm = parseInt(sp.ParkingLotID ?? sp.parkingLotId ?? parkingLotId) || parkingLotId;
      const terminalCode = sp.TerminalCode ?? sp.terminalCode ?? '';
      const spotNumber = sp.SpotNumber ?? sp.spotNumber ?? '';
      const isReservedRaw = sp.IsReserved ?? sp.isReserved ?? 0;
      const isReservedParsed = parseInt(isReservedRaw);
      const isReserved = isReservedParsed === 1 ? 1 : 0;
      const rawStatus = (sp.SpotStatus ?? sp.spotStatus ?? '').toString().trim().toUpperCase();
      const spotStatus = rawStatus === 'EMPTY' || rawStatus === 'OCCUPIED'
        ? rawStatus
        : (isReserved === 1 ? 'OCCUPIED' : 'EMPTY');
      return {
        spotId,
        parkingLotId: parkingLotIdNorm,
        terminalCode,
        spotNumber,
        spotStatus,
        isReserved,
      };
    });
    return res.status(200).json({ summary, terminals, spots });
  } catch (error) {
    console.error('Parking lot detail error:', error);
    return res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
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
const { getPool, sql } = require('../config/database');

/**
 * GET /api/parking/payment-statistics
 * Otopark ödeme istatistiklerini döndürür
 * AirportParkingSystem.ParkingPayments tablosundan hesaplar
 */
router.get('/payment-statistics', async (req, res) => {
  console.log('📥 GET /api/parking/payment-statistics endpoint called');
  try {
    const pool = await getPool();

    // Ödeme istatistiklerini hesapla
    const result = await pool.request().query(`
      SELECT * FROM AirportParkingSystem.fn_PaymentSummary()
    `);

    // Tek satır döndürür
    if (!result.recordset || result.recordset.length === 0) {
      return res.json({
        success: true,
        data: {
          totalRevenue: 0,
          totalTransactionCount: 0,
          averagePayment: 0
        }
      });
    }

    const stats = result.recordset[0];

    // Debug: Gelen kolonları logla
    console.log('🔍 Raw database result:', JSON.stringify(stats, null, 2));
    console.log('🔍 Available keys:', Object.keys(stats));

    // Kolon isimlerini normalize et (case-insensitive)
    const getValue = (obj, ...keys) => {
      for (const key of keys) {
        const foundKey = Object.keys(obj).find(k => k.toLowerCase() === key.toLowerCase());
        if (foundKey && obj[foundKey] != null) {
          return obj[foundKey];
        }
      }
      return null;
    };

    // Function'dan direkt gelen kolonlar: TotalRevenue, TotalTransactionCount, AveragePayment
    const totalRevenue = getValue(stats, 'TotalRevenue', 'totalRevenue', 'total_revenue') || 0;
    const totalTransactionCount = getValue(stats, 'TotalTransactionCount', 'totalTransactionCount', 'total_transaction_count') || 0;
    const averagePayment = getValue(stats, 'AveragePayment', 'averagePayment', 'average_payment') || 0;

    console.log('✅ Parking payment statistics retrieved:', {
      totalRevenue,
      totalTransactionCount,
      averagePayment
    });

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

router.get('/parking-lots', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().execute('AirportParkingSystem.usp_GetParkingLotsForDropdown');
    const rows = (result.recordset || []).map((row) => {
      const parkingLotID = row.ParkingLotID ?? row.parkingLotID ?? row.LotID ?? row.lotID ?? null;
      const lotName = row.LotName ?? row.lotName ?? row.ParkingLotName ?? row.parkingLotName ?? '';
      return { parkingLotID, lotName };
    });
    return res.json({ success: true, data: rows });
  } catch (error) {
    console.error('Parking lots dropdown error:', error);
    return res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

// GET /api/parking/parking-lots/with-occupancy
router.get('/parking-lots/with-occupancy', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().execute('AirportParkingSystem.usp_GetParkingLotsWithOccupancy');
    const rows = (result.recordset || []).map((row) => ({
      lotName: row.LotName ?? row.lotName ?? '',
      occupancyRate: typeof row.OccupancyRate === 'number'
        ? row.OccupancyRate
        : parseFloat(row.OccupancyRate ?? row.occupancyRate ?? 0) || 0
    }));
    return res.status(200).json(rows);
  } catch (error) {
    console.error('Parking lots with occupancy error:', error);
    return res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});
router.post('/entry', async (req, res) => {
  try {
    const db = require('../config/database');
    const getPool = db.getPool;
    const sql = db.sql;

    const staffHeader = req.headers['x-user-id'] ?? req.headers['x-userid'] ?? req.headers['x_user_id'];
    const staffUserId = staffHeader !== undefined ? parseInt(staffHeader) : NaN;
    if (isNaN(staffUserId)) {
      return res.status(401).json({ success: false, code: 'AUTH_REQUIRED', errorMessage: 'StaffUserID not found in auth context' });
    }

    const body = req.body || {};
    const plateNumber = (body.plateNumber || '').toString().trim();
    const typeId = body.typeId !== undefined ? parseInt(body.typeId) : NaN;
    const ownerFullName = (body.ownerFullName || '').toString().trim();
    const ownerPhone = (body.ownerPhone || '').toString().trim();
    const parkingLotId = body.parkingLotId !== undefined ? parseInt(body.parkingLotId) : NaN;
    const spotNumber = (body.spotNumber || '').toString().trim();

    if (!plateNumber || isNaN(typeId) || !ownerFullName || !ownerPhone || isNaN(parkingLotId) || !spotNumber) {
      return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', errorMessage: 'Eksik veya hatalı alanlar' });
    }

    const pool = await getPool();
    const request = pool.request();
    request.input('StaffUserID', sql.Int, staffUserId);
    request.input('PlateNumber', sql.VarChar(20), plateNumber);
    request.input('TypeID', sql.Int, typeId);
    request.input('OwnerFullName', sql.VarChar(200), ownerFullName);
    request.input('OwnerPhone', sql.VarChar(50), ownerPhone);
    request.input('ParkingLotID', sql.Int, parkingLotId);
    request.input('SpotNumber', sql.VarChar(20), spotNumber);

    const result = await request.execute('AirportParkingSystem.usp_CreateParkingEntry');
    const row = (result.recordset && result.recordset[0]) ? result.recordset[0] : null;
    if (!row) {
      return res.status(500).json({ success: false, code: 'NO_RESULT', errorMessage: 'İşlem sonucu alınamadı' });
    }
    const success = (row.Success ?? row.success ?? 0) === true || (row.Success ?? 0) === 1;
    if (!success) {
      const errorCode = row.ErrorCode ?? row.errorCode ?? 0;
      const errorMessage = row.ErrorMessage ?? row.errorMessage ?? 'İşlem başarısız';
      return res.status(400).json({ success: false, code: errorCode, errorMessage });
    }
    return res.json({ success: true, data: row });
  } catch (error) {
    console.error('Create parking entry error:', error);
    return res.status(500).json({ success: false, code: 'SERVER_ERROR', errorMessage: 'Sunucu hatası: ' + error.message });
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
        totalRevenue: parseFloat(totalRevenue) || 0,
        totalTransactionCount: parseInt(totalTransactionCount) || 0,
        averagePayment: parseFloat(averagePayment) || 0
      }
    });

  } catch (error) {
    console.error('❌ Parking payment statistics error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: {
        totalRevenue: 0,
        totalTransactionCount: 0,
        averagePayment: 0
      }
    });
  }
});

/**
 * GET /api/parking/payment-list
 * Otopark ödeme detay listesini döndürür
 * AirportParkingSystem.fn_ParkingPaymentDetailList() function'ından alır
 */
router.get('/payment-list', async (req, res) => {
  console.log('📥 GET /api/parking/payment-list endpoint called');
  try {
    const pool = await getPool();

    // Ödeme detay listesini getir
    const result = await pool.request().query(`
      SELECT * FROM AirportParkingSystem.fn_ParkingPaymentDetailList()
    `);

    console.log('🔍 Raw database result count:', result.recordset?.length || 0);
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 Sample row keys:', Object.keys(result.recordset[0]));
      console.log('🔍 Sample row Status:', result.recordset[0].Status || result.recordset[0].status);
    }

    if (!result.recordset || result.recordset.length === 0) {
      console.log('⚠️ No payment records found in database');
      return res.json({
        success: true,
        data: []
      });
    }

    // Kolon isimlerini normalize et (case-insensitive)
    const getValue = (obj, ...keys) => {
      for (const key of keys) {
        const foundKey = Object.keys(obj).find(k => k.toLowerCase() === key.toLowerCase());
        if (foundKey && obj[foundKey] != null) {
          return obj[foundKey];
        }
      }
      return null;
    };

    // Tarih formatı: ISO string'den HH:mm formatına çevir
    const formatTime = (dateValue) => {
      if (!dateValue) return '';
      
      try {
        // Date object ise
        if (dateValue instanceof Date) {
          const hours = String(dateValue.getHours()).padStart(2, '0');
          const minutes = String(dateValue.getMinutes()).padStart(2, '0');
          return `${hours}:${minutes}`;
        }
        
        // String ise (ISO format: 2025-12-25T10:15:00)
        if (typeof dateValue === 'string') {
          const date = new Date(dateValue);
          if (!isNaN(date.getTime())) {
            const hours = String(date.getHours()).padStart(2, '0');
            const minutes = String(date.getMinutes()).padStart(2, '0');
            return `${hours}:${minutes}`;
          }
          return dateValue; // Eğer parse edilemezse olduğu gibi döndür
        }
        
        return '';
      } catch (error) {
        console.warn('⚠️ Date format error:', error);
        return '';
      }
    };

    // Ödeme listesini map et
    const payments = result.recordset.map(row => {
      const paymentId = getValue(row, 'PaymentID', 'paymentId', 'payment_id') || '';
      const plateNumber = getValue(row, 'PlateNumber', 'plateNumber', 'plate_number') || '';
      const vehicleType = getValue(row, 'VehicleType', 'vehicleType', 'vehicle_type') || '';
      const ownerName = getValue(row, 'OwnerName', 'ownerName', 'owner_name') || '';
      const spotNumber = getValue(row, 'SpotNumber', 'spotNumber', 'spot_number') || '';
      
      const checkInTimeRaw = getValue(row, 'CheckInTime', 'checkInTime', 'check_in_time');
      const checkInTime = formatTime(checkInTimeRaw);
      
      const checkOutTimeRaw = getValue(row, 'CheckOutTime', 'checkOutTime', 'check_out_time');
      const checkOutTime = formatTime(checkOutTimeRaw);
      
      const stayDurationMinutes = getValue(row, 'StayDurationMinutes', 'stayDurationMinutes', 'stay_duration_minutes') || 0;
      const paymentMethod = getValue(row, 'PaymentMethod', 'paymentMethod', 'payment_method') || '';
      let status = getValue(row, 'Status', 'status') || '';
      
      // Status değerlerini Türkçe'ye çevir (case-insensitive)
      const statusLower = (status || '').toLowerCase().trim();
      if (statusLower === 'completed') {
        status = 'Tamamlandı';
      } else if (statusLower === 'pending') {
        status = 'Bekleyen';
      } else if (statusLower === 'cancelled' || statusLower === 'canceled') {
        status = 'İptal';
      }
      // Eğer zaten Türkçe ise olduğu gibi bırak
      
      const amount = getValue(row, 'Amount', 'amount') || 0;

      return {
        paymentId,
        plateNumber,
        vehicleType,
        ownerName,
        spotNumber,
        checkInTime,
        checkOutTime,
        stayDurationMinutes: parseInt(stayDurationMinutes) || 0,
        paymentMethod,
        status,
        amount: parseFloat(amount) || 0
      };
    });

    console.log('✅ Parking payment list retrieved:', payments.length, 'payments');
    if (payments.length > 0) {
      console.log('📋 Sample payment:', JSON.stringify(payments[0], null, 2));
    }

    res.json({
      success: true,
      data: payments
    });

  } catch (error) {
    console.error('❌ Parking payment list error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: []
    });
  }
});

/**
 * GET /api/parking/reservation-list
 * Otopark rezervasyon detay listesini döndürür
 * AirportParkingSystem.fn_ParkingReservationDetailList() function'ından alır
 */
router.get('/reservation-list', async (req, res) => {
  console.log('📥 GET /api/parking/reservation-list endpoint called');
  try {
    const pool = await getPool();

    // Rezervasyon detay listesini getir
    const result = await pool.request().query(`
      SELECT * FROM AirportParkingSystem.fn_ParkingReservationDetailList()
    `);

    console.log('🔍 Raw database result count:', result.recordset?.length || 0);
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 Sample row keys:', Object.keys(result.recordset[0]));
    }

    if (!result.recordset || result.recordset.length === 0) {
      console.log('⚠️ No reservation records found in database');
      return res.json({
        success: true,
        data: []
      });
    }

    // Kolon isimlerini normalize et (case-insensitive)
    const getValue = (obj, ...keys) => {
      for (const key of keys) {
        const foundKey = Object.keys(obj).find(k => k.toLowerCase() === key.toLowerCase());
        if (foundKey && obj[foundKey] != null) {
          return obj[foundKey];
        }
      }
      return null;
    };

    // Tarih formatı: ISO string'den okunabilir formata çevir
    const formatDateTime = (dateValue) => {
      if (!dateValue) return '';
      
      try {
        // Date object ise
        if (dateValue instanceof Date) {
          return dateValue.toISOString();
        }
        
        // String ise (ISO format: 2024-01-15T10:00:00)
        if (typeof dateValue === 'string') {
          const date = new Date(dateValue);
          if (!isNaN(date.getTime())) {
            return date.toISOString();
          }
          return dateValue; // Eğer parse edilemezse olduğu gibi döndür
        }
        
        return '';
      } catch (error) {
        console.warn('⚠️ Date format error:', error);
        return '';
      }
    };

    // Rezervasyon listesini map et
    const reservations = result.recordset.map(row => {
      const reservationNo = getValue(row, 'ReservationNo', 'reservationNo', 'reservation_no') || '';
      const plateNumber = getValue(row, 'PlateNumber', 'plateNumber', 'plate_number') || '';
      const customerName = getValue(row, 'CustomerName', 'customerName', 'customer_name') || '';
      const phone = getValue(row, 'Phone', 'phone') || '';
      const parkingSpot = getValue(row, 'ParkingSpot', 'parkingSpot', 'parking_spot') || '';
      
      const startTimeRaw = getValue(row, 'StartTime', 'startTime', 'start_time');
      const startTime = formatDateTime(startTimeRaw);
      
      const endTimeRaw = getValue(row, 'EndTime', 'endTime', 'end_time');
      const endTime = formatDateTime(endTimeRaw);
      
      const amount = getValue(row, 'Amount', 'amount') || 0;
      let status = getValue(row, 'Status', 'status') || '';
      
      // Status değerlerini normalize et (case-insensitive)
      const statusLower = (status || '').toLowerCase().trim();
      if (statusLower === 'active' || statusLower === 'aktif') {
        status = 'active';
      } else if (statusLower === 'completed' || statusLower === 'tamamlandı' || statusLower === 'completed') {
        status = 'completed';
      } else if (statusLower === 'cancelled' || statusLower === 'canceled' || statusLower === 'iptal') {
        status = 'cancelled';
      } else if (statusLower === 'pending' || statusLower === 'bekleyen') {
        status = 'pending';
      }
      
      const paymentMethod = getValue(row, 'PaymentMethod', 'paymentMethod', 'payment_method') || '';

      return {
        reservationNo,
        plateNumber,
        customerName,
        phone,
        parkingSpot,
        startTime,
        endTime,
        amount: parseFloat(amount) || 0,
        status,
        paymentMethod
      };
    });

    console.log('✅ Parking reservation list retrieved:', reservations.length, 'reservations');
    if (reservations.length > 0) {
      console.log('📋 Sample reservation:', JSON.stringify(reservations[0], null, 2));
    }

    res.json({
      success: true,
      data: reservations
    });

  } catch (error) {
    console.error('❌ Parking reservation list error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: []
    });
  }
});

/**
 * PUT /api/parking/update-reservation
 * Otopark rezervasyon bilgilerini günceller
 * AirportParkingSystem.sp_UpdateParkingReservation stored procedure'ünü çağırır
 */
router.put('/update-reservation', async (req, res) => {
  console.log('📥 PUT /api/parking/update-reservation endpoint called');
  console.log('📋 Request body:', req.body);
  
  try {
    const { reservationCode, plateNumber, fullName, phone, status, actionUserId } = req.body;

    // Parametre kontrolü
    if (!reservationCode || !plateNumber || !fullName || !phone || !status || !actionUserId) {
      return res.status(400).json({
        success: false,
        message: 'Tüm alanlar zorunludur: reservationCode, plateNumber, fullName, phone, status, actionUserId'
      });
    }

    const pool = await getPool();

    // Stored procedure'ü çağır
    const request = pool.request();
    request.input('ReservationCode', sql.VarChar(20), reservationCode);
    request.input('PlateNumber', sql.VarChar(20), plateNumber);
    request.input('FullName', sql.VarChar(100), fullName);
    request.input('Phone', sql.VarChar(20), phone);
    request.input('Status', sql.VarChar(20), status);
    request.input('ActionUserID', sql.Int, actionUserId);

    const result = await request.execute('AirportParkingSystem.sp_UpdateParkingReservation');

    console.log('✅ Stored procedure executed successfully');
    console.log('📋 Procedure result:', result);

    // Stored procedure başarılı bir şekilde çalıştıysa
    res.json({
      success: true,
      message: 'Rezervasyon başarıyla güncellendi',
      data: {
        reservationCode,
        plateNumber,
        fullName,
        phone,
        status
      }
    });

  } catch (error) {
    console.error('❌ Parking reservation update error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});


module.exports = router;

