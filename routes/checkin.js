const express = require('express');
const router = express.Router();
const { getPool, sql } = require('../config/database');

/**
 * GET /api/checkin/summary-today
 * Bugünkü check-in özet istatistiklerini döndürür
 * Veritabanındaki fn_ReservationSummaryToday function'ını çağırır
 */
router.get('/summary-today', async (req, res) => {
  try {
    const pool = await getPool();

    // Table-valued function'ı çağır - Kolon isimlerini alias ile belirliyoruz
    const result = await pool.request().query(`
      SELECT 
        TodayReservationCount AS TodayCheckInCount,
        CompletedReservationCount AS CompletedCheckInCount,
        PendingReservationCount AS PendingCheckInCount,
        CancelledReservationCount AS CancelledCheckInCount
      FROM FlightReservationSystem.fn_ReservationSummaryToday()
    `);

    // Function tek satır döndürür
    if (!result.recordset || result.recordset.length === 0) {
      // Veri yoksa varsayılan değerler döndür
      return res.json({
        success: true,
        data: {
          todayCheckInCount: 0,
          completedCheckInCount: 0,
          pendingCheckInCount: 0,
          cancelledCheckInCount: 0
        }
      });
    }

    const summary = result.recordset[0];

    // Debug: Gelen kolonları logla
    console.log('🔍 Raw database result:', JSON.stringify(summary, null, 2));
    console.log('🔍 Available keys:', Object.keys(summary));

    // Artık alias kullandığımız için kolon isimleri standart
    // Ama yine de farklı varyasyonları kontrol ediyoruz (güvenlik için)
    const todayCheckInCount = summary.TodayCheckInCount ||
      summary.todayCheckInCount ||
      summary.TodayReservationCount ||
      summary.todayReservationCount ||
      0;

    const completedCheckInCount = summary.CompletedCheckInCount ||
      summary.completedCheckInCount ||
      summary.CompletedReservationCount ||
      summary.completedReservationCount ||
      0;

    const pendingCheckInCount = summary.PendingCheckInCount ||
      summary.pendingCheckInCount ||
      summary.PendingReservationCount ||
      summary.pendingReservationCount ||
      0;

    const cancelledCheckInCount = summary.CancelledCheckInCount ||
      summary.cancelledCheckInCount ||
      summary.CancelledReservationCount ||
      summary.cancelledReservationCount ||
      0;

    console.log('✅ Check-in summary retrieved:', {
      todayCheckInCount,
      completedCheckInCount,
      pendingCheckInCount,
      cancelledCheckInCount
    });

    res.json({
      success: true,
      data: {
        todayCheckInCount: parseInt(todayCheckInCount) || 0,
        completedCheckInCount: parseInt(completedCheckInCount) || 0,
        pendingCheckInCount: parseInt(pendingCheckInCount) || 0,
        cancelledCheckInCount: parseInt(cancelledCheckInCount) || 0
      }
    });

  } catch (error) {
    console.error('❌ Check-in summary error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: {
        todayCheckInCount: 0,
        completedCheckInCount: 0,
        pendingCheckInCount: 0,
        cancelledCheckInCount: 0
      }
    });
  }
});

/**
 * GET /api/checkin/last-completed-today
 * Bugünkü tamamlanan son 5 check-in işlemini döndürür
 * Veritabanındaki fn_LastCompletedCheckInsToday function'ını çağırır
 */
router.get('/last-completed-today', async (req, res) => {
  try {
    const pool = await getPool();

    // Table-valued function'ı çağır
    const result = await pool.request().query(`
      SELECT *
      FROM FlightReservationSystem.fn_LastCompletedCheckInsToday()
    `);

    // Function boş liste döndürebilir
    if (!result.recordset || result.recordset.length === 0) {
      return res.json({
        success: true,
        data: []
      });
    }

    // Debug: İlk satırın kolon isimlerini logla
    if (result.recordset.length > 0) {
      console.log('🔍 Raw database result (first row):', JSON.stringify(result.recordset[0], null, 2));
      console.log('🔍 Available keys:', Object.keys(result.recordset[0]));
    }

    // Veritabanından gelen verileri API formatına map et
    // Function zaten formatlanmış verileri döndürüyor (ReservationNo, PassengerName, Route, CheckInTime)
    const checkIns = result.recordset.map(row => {
      // Kolon isimlerini normalize et (case-insensitive)
      const getValue = (obj, ...keys) => {
        for (const key of keys) {
          const foundKey = Object.keys(obj).find(k => k.toLowerCase() === key.toLowerCase());
          if (foundKey && obj[foundKey] != null && obj[foundKey] !== '') {
            return obj[foundKey];
          }
        }
        return null;
      };

      // Function zaten formatlanmış verileri döndürüyor, direkt kullan
      // ReservationNo: Function'dan direkt geliyor (zaten "R4" formatında)
      const reservationNo = getValue(row, 'ReservationNo', 'reservationNo', 'reservation_no') || '';

      // PassengerName: Function'dan direkt geliyor
      const passengerName = getValue(row, 'PassengerName', 'passengerName', 'passenger_name') || '';

      // FlightNo: Function'dan direkt geliyor
      const flightNo = getValue(row, 'FlightNo', 'flightNo', 'flight_no', 'FlightID', 'flightId') || '';

      // Route: Function'dan direkt geliyor (zaten "SAW → ADB" formatında, ama "?" olabilir)
      let route = getValue(row, 'Route', 'route') || '';
      // Eğer "?" varsa "→" ile değiştir
      if (route && route.includes('?')) {
        route = route.replace(/\s*\?\s*/g, ' → ');
      }

      // Status: Function'dan direkt geliyor veya "Tamamlanan"
      const status = getValue(row, 'Status', 'status') || 'Tamamlanan';

      // CheckInTime: Function'dan direkt geliyor (HH:mm formatında string olabilir)
      let checkInTime = getValue(row, 'CheckInTime', 'checkInTime', 'check_in_time', 'CheckIn Time');
      let checkInTimeFormatted = '';
      
      if (checkInTime) {
        // Eğer string ve HH:mm formatındaysa direkt kullan
        if (typeof checkInTime === 'string' && /^\d{2}:\d{2}$/.test(checkInTime)) {
          checkInTimeFormatted = checkInTime;
        } else if (checkInTime instanceof Date) {
          // Date objesi ise formatla
          const hours = checkInTime.getHours().toString().padStart(2, '0');
          const minutes = checkInTime.getMinutes().toString().padStart(2, '0');
          checkInTimeFormatted = `${hours}:${minutes}`;
        } else {
          // Diğer durumlarda Date'e çevirmeyi dene
          const date = new Date(checkInTime);
          if (!isNaN(date.getTime())) {
            const hours = date.getHours().toString().padStart(2, '0');
            const minutes = date.getMinutes().toString().padStart(2, '0');
            checkInTimeFormatted = `${hours}:${minutes}`;
          } else if (typeof checkInTime === 'string') {
            // String ise ilk 5 karakteri al
            checkInTimeFormatted = checkInTime.substring(0, 5);
          }
        }
      }

      return {
        ReservationNo: reservationNo,
        PassengerName: passengerName,
        FlightNo: flightNo,
        Route: route,
        Status: status,
        CheckInTime: checkInTimeFormatted
      };
    });

    console.log('✅ Last completed check-ins retrieved:', checkIns.length, 'items');

    res.json({
      success: true,
      data: checkIns
    });

  } catch (error) {
    console.error('❌ Last completed check-ins error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: []
    });
  }
});

/**
 * GET /api/checkin/ticket-list
 * Check-in yapılacak bilet listesini döndürür
 * Veritabanındaki fn_CheckInTicketList function'ını çağırır
 */
router.get('/ticket-list', async (req, res) => {
  try {
    const pool = await getPool();

    // Table-valued function'ı çağır
    const result = await pool.request().query(`
      SELECT *
      FROM FlightReservationSystem.fn_CheckInTicketList()
    `);

    // Function boş liste döndürebilir
    if (!result.recordset || result.recordset.length === 0) {
      return res.json({
        success: true,
        data: []
      });
    }

    // Debug: İlk satırın kolon isimlerini logla
    if (result.recordset.length > 0) {
      console.log('🔍 Ticket list raw database result (first row):', JSON.stringify(result.recordset[0], null, 2));
      console.log('🔍 Available keys:', Object.keys(result.recordset[0]));
    }

    // Veritabanından gelen verileri API formatına map et
    const tickets = result.recordset.map(row => {
      // Kolon isimlerini normalize et (case-insensitive)
      const getValue = (obj, ...keys) => {
        for (const key of keys) {
          const foundKey = Object.keys(obj).find(k => k.toLowerCase() === key.toLowerCase());
          if (foundKey && obj[foundKey] != null && obj[foundKey] !== '') {
            return obj[foundKey];
          }
        }
        return null;
      };

      // ReservationNo: Function'dan direkt geliyor
      const reservationNo = getValue(row, 'ReservationNo', 'reservationNo', 'reservation_no') || '';

      // PassengerName: Function'dan direkt geliyor
      const passengerName = getValue(row, 'PassengerName', 'passengerName', 'passenger_name') || '';

      // PassportNo: NULL veya boş ise "Pasaport girilmedi"
      const passportNo = getValue(row, 'PassportNo', 'passportNo', 'passport_no');
      const passportDisplay = passportNo || 'Pasaport girilmedi';

      // Route: Function'dan direkt geliyor, "?" varsa "→" ile değiştir
      let route = getValue(row, 'Route', 'route') || '';
      if (route && route.includes('?')) {
        route = route.replace(/\s*\?\s*/g, ' → ');
      }

      // ReservationDate: "YYYY-MM-DD · HH:mm" formatına çevir
      const reservationDate = getValue(row, 'ReservationDate', 'reservationDate', 'reservation_date');
      let reservationDateFormatted = '';
      if (reservationDate) {
        try {
          const date = reservationDate instanceof Date ? reservationDate : new Date(reservationDate);
          if (!isNaN(date.getTime())) {
            const year = date.getFullYear();
            const month = (date.getMonth() + 1).toString().padStart(2, '0');
            const day = date.getDate().toString().padStart(2, '0');
            const hours = date.getHours().toString().padStart(2, '0');
            const minutes = date.getMinutes().toString().padStart(2, '0');
            reservationDateFormatted = `${year}-${month}-${day} · ${hours}:${minutes}`;
          }
        } catch (e) {
          console.warn('Date parsing error:', e);
        }
      }

      // SeatInfo: Function'dan direkt geliyor
      const seatInfo = getValue(row, 'SeatInfo', 'seatInfo', 'seat_info') || '';

      // Status: Function'dan direkt geliyor ("Bekleyen" veya "Tamamlanan")
      const status = getValue(row, 'Status', 'status') || 'Bekleyen';

      return {
        ReservationNo: reservationNo,
        PassengerName: passengerName,
        PassportNo: passportDisplay,
        Route: route,
        ReservationDate: reservationDateFormatted,
        SeatInfo: seatInfo,
        Status: status
      };
    });

    console.log('✅ Ticket list retrieved:', tickets.length, 'items');

    res.json({
      success: true,
      data: tickets
    });

  } catch (error) {
    console.error('❌ Ticket list error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: []
    });
  }
});

/**
 * GET /api/checkin/passenger-detail-list
 * Yolcu detay listesini döndürür
 * Veritabanındaki fn_PassengerDetailList function'ını çağırır
 */
router.get('/passenger-detail-list', async (req, res) => {
  try {
    const pool = await getPool();

    // Table-valued function'ı çağır
    const result = await pool.request().query(`
      SELECT *
      FROM FlightReservationSystem.fn_PassengerDetailList()
    `);

    // Function boş liste döndürebilir
    if (!result.recordset || result.recordset.length === 0) {
      return res.json({
        success: true,
        data: []
      });
    }

    // Debug: İlk satırın kolon isimlerini logla
    if (result.recordset.length > 0) {
      console.log('🔍 Passenger detail list raw database result (first row):', JSON.stringify(result.recordset[0], null, 2));
      console.log('🔍 Available keys:', Object.keys(result.recordset[0]));
    }

    // Veritabanından gelen verileri API formatına map et
    const passengers = result.recordset.map(row => {
      // Kolon isimlerini normalize et (case-insensitive)
      const getValue = (obj, ...keys) => {
        for (const key of keys) {
          const foundKey = Object.keys(obj).find(k => k.toLowerCase() === key.toLowerCase());
          if (foundKey && obj[foundKey] != null && obj[foundKey] !== '') {
            return obj[foundKey];
          }
        }
        return null;
      };

      // ReservationNo: Function'dan direkt geliyor
      const reservationNo = getValue(row, 'ReservationNo', 'reservationNo', 'reservation_no') || '';

      // FullName: Function'dan direkt geliyor
      const fullName = getValue(row, 'FullName', 'fullName', 'full_name') || '';

      // Age: Function'dan direkt geliyor
      const age = getValue(row, 'Age', 'age');

      // Gender: Function'dan direkt geliyor
      const gender = getValue(row, 'Gender', 'gender') || '';

      // PassportNo: Function'dan direkt geliyor
      const passportNo = getValue(row, 'PassportNo', 'passportNo', 'passport_no') || '';

      // Nationality: Function'dan direkt geliyor
      const nationality = getValue(row, 'Nationality', 'nationality') || '';

      // Email: Function'dan direkt geliyor
      const email = getValue(row, 'Email', 'email') || '';

      // Phone: Function'dan direkt geliyor
      const phone = getValue(row, 'Phone', 'phone') || '';

      // FlightNo: Function'dan direkt geliyor
      const flightNo = getValue(row, 'FlightNo', 'flightNo', 'flight_no') || '';

      // Route: Function'dan direkt geliyor, "?" varsa "→" ile değiştir
      let route = getValue(row, 'Route', 'route') || '';
      if (route && route.includes('?')) {
        route = route.replace(/\s*\?\s*/g, ' → ');
      }

      // SeatNumber: Function'dan direkt geliyor
      const seatNumber = getValue(row, 'SeatNumber', 'seatNumber', 'seat_number') || '';

      // Status: Function'dan direkt geliyor
      const status = getValue(row, 'Status', 'status') || '';

      return {
        reservationNo: reservationNo,
        fullName: fullName,
        age: age,
        gender: gender,
        passportNo: passportNo,
        nationality: nationality,
        email: email,
        phone: phone,
        flightNo: flightNo,
        route: route,
        seatNumber: seatNumber,
        status: status
      };
    });

    console.log('✅ Passenger detail list retrieved:', passengers.length, 'items');

    res.json({
      success: true,
      data: passengers
    });

  } catch (error) {
    console.error('❌ Passenger detail list error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: []
    });
  }
});

module.exports = router;
