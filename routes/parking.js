const express = require('express');
const router = express.Router();
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




