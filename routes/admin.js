const express = require('express');
const router = express.Router();
const { getPool, sql } = require('../config/database');

/**
 * GET /api/admin/dashboard-stats
 * Admin dashboard istatistiklerini döndürür
 * 4 farklı stored procedure'den veri çeker
 */
router.get('/dashboard-stats', async (req, res) => {
  console.log('📥 GET /api/admin/dashboard-stats endpoint called');
  try {
    const pool = await getPool();

    // Tüm stored procedure'leri paralel olarak çağır
    const [todayFlightsResult, activeReservationsResult, occupiedParkingResult, totalRevenueResult] = await Promise.all([
      pool.request().execute('FlightReservationSystem.GetTodayActiveFlightCount'),
      pool.request().execute('FlightReservationSystem.GetActiveReservationCount'),
      pool.request().execute('AirportParkingSystem.GetOccupiedParkingCount'),
      pool.request().execute('dbo.GetTotalRevenue'),
    ]);

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

    // Stored procedure'lerden dönen değerleri çıkar
    // Gerçek kolon isimleri görüntüden alındı:
    // - GetTodayActiveFlightCount → TodayActiveFlightCount
    // - GetActiveReservationCount → ActiveReservationCount
    // - GetOccupiedParkingCount → Value
    // - GetTotalRevenue → TotalRevenue
    const todayFlights = getValue(todayFlightsResult.recordset?.[0] || {}, 'TodayActiveFlightCount', 'todayActiveFlightCount', 'Count', 'count') || 0;
    const activeReservations = getValue(activeReservationsResult.recordset?.[0] || {}, 'ActiveReservationCount', 'activeReservationCount', 'Count', 'count') || 0;
    const occupiedParkingSpots = getValue(occupiedParkingResult.recordset?.[0] || {}, 'Value', 'value', 'OccupiedParkingCount', 'occupiedParkingCount', 'Count', 'count') || 0;
    const totalRevenue = getValue(totalRevenueResult.recordset?.[0] || {}, 'TotalRevenue', 'totalRevenue', 'Revenue', 'revenue', 'Amount', 'amount') || 0;

    console.log('✅ Admin dashboard stats retrieved:', {
      todayFlights,
      activeReservations,
      occupiedParkingSpots,
      totalRevenue
    });

    // Debug: Raw results
    console.log('🔍 Today flights result:', JSON.stringify(todayFlightsResult.recordset?.[0] || {}, null, 2));
    console.log('🔍 Active reservations result:', JSON.stringify(activeReservationsResult.recordset?.[0] || {}, null, 2));
    console.log('🔍 Occupied parking result:', JSON.stringify(occupiedParkingResult.recordset?.[0] || {}, null, 2));
    console.log('🔍 Total revenue result:', JSON.stringify(totalRevenueResult.recordset?.[0] || {}, null, 2));

    res.json({
      success: true,
      data: {
        todayFlights: parseInt(todayFlights) || 0,
        activeReservations: parseInt(activeReservations) || 0,
        occupiedParkingSpots: parseInt(occupiedParkingSpots) || 0,
        totalRevenue: parseFloat(totalRevenue) || 0,
      }
    });

  } catch (error) {
    console.error('❌ Admin dashboard stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: {
        todayFlights: 0,
        activeReservations: 0,
        occupiedParkingSpots: 0,
        totalRevenue: 0,
      }
    });
  }
});

/**
 * GET /api/admin/today-flights
 * Bugünkü son 5 uçuşu döndürür
 * dbo.GetTodayLast5Flights stored procedure'ünü çağırır
 */
router.get('/today-flights', async (req, res) => {
  console.log('📥 GET /api/admin/today-flights endpoint called');
  try {
    const pool = await getPool();

    // Stored procedure'ü çağır
    const result = await pool.request().execute('dbo.GetTodayLast5Flights');

    console.log('🔍 Raw database result count:', result.recordset?.length || 0);
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 Sample row keys:', Object.keys(result.recordset[0]));
    }

    if (!result.recordset || result.recordset.length === 0) {
      console.log('⚠️ No flights found in database');
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

    // Route formatını parse et: "SAW ? AYT" → {departure: "SAW", arrival: "AYT"}
    const parseRoute = (routeString) => {
      if (!routeString) return { departure: '', arrival: '' };
      
      // "SAW ? AYT" formatını parse et
      const parts = routeString.split('?').map(s => s.trim());
      if (parts.length === 2) {
        return { departure: parts[0], arrival: parts[1] };
      }
      
      // Eğer "?" yoksa, boşlukla ayrılmış olabilir
      const spaceParts = routeString.trim().split(/\s+/);
      if (spaceParts.length >= 2) {
        return { departure: spaceParts[0], arrival: spaceParts[spaceParts.length - 1] };
      }
      
      return { departure: routeString, arrival: '' };
    };

    // Status'u Türkçe'ye çevir
    const translateStatus = (status) => {
      if (!status) return 'Bilinmiyor';
      const statusLower = status.toLowerCase().trim();
      
      if (statusLower === 'delayed' || statusLower === 'gecikti') {
        return 'Gecikti';
      } else if (statusLower === 'scheduled' || statusLower === 'zamanında' || statusLower === 'planlanan') {
        return 'Zamanında';
      } else if (statusLower === 'completed' || statusLower === 'tamamlandı') {
        return 'Tamamlandı';
      } else if (statusLower === 'boarding' || statusLower === 'biniş') {
        return 'Biniş';
      }
      
      return status; // Eğer tanınmazsa olduğu gibi döndür
    };

    // Uçuş listesini map et
    const flights = result.recordset.map((row, index) => {
      const flightCode = getValue(row, 'FlightCode', 'flightCode', 'flight_code') || '';
      const route = getValue(row, 'Route', 'route') || '';
      const status = getValue(row, 'Status', 'status') || '';
      
      const { departure, arrival } = parseRoute(route);
      const translatedStatus = translateStatus(status);

      return {
        id: `FL${index + 1}`,
        flightNo: flightCode,
        departure: departure,
        arrival: arrival,
        status: translatedStatus,
      };
    });

    console.log('✅ Today flights retrieved:', flights.length, 'flights');
    if (flights.length > 0) {
      console.log('📋 Sample flight:', JSON.stringify(flights[0], null, 2));
    }

    res.json({
      success: true,
      data: flights
    });

  } catch (error) {
    console.error('❌ Admin today flights error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: []
    });
  }
});

/**
 * GET  
 * Tüm kapıları döndürür
 * FlightReservationSystem.fn_GetAllGates() function'ından alır
 */
router.get('/gates', async (req, res) => {
  console.log('📥 GET /api/admin/gates endpoint called');
  try {
    const pool = await getPool();

    // Kapı listesini getir
    const result = await pool.request().query(`
      SELECT * FROM FlightReservationSystem.fn_GetAllGates()
    `);

    console.log('🔍 Raw database result count:', result.recordset?.length || 0);
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 Sample row keys:', Object.keys(result.recordset[0]));
    }

    if (!result.recordset || result.recordset.length === 0) {
      console.log('⚠️ No gates found in database');
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

    // Status'u normalize et (Scheduled, Delayed, Completed → Available, Occupied, Maintenance)
    const normalizeStatus = (status) => {
      if (!status) return 'Available';
      const statusLower = (status || '').toLowerCase().trim();
      
      if (statusLower === 'scheduled' || statusLower === 'zamanında' || statusLower === 'planlanan') {
        return 'Available';
      } else if (statusLower === 'delayed' || statusLower === 'gecikti') {
        return 'Occupied';
      } else if (statusLower === 'completed' || statusLower === 'tamamlandı') {
        return 'Maintenance';
      }
      
      // Eğer tanınmazsa olduğu gibi döndür veya Available yap
      return status;
    };

    // Debug: İlk satırın tüm kolonlarını logla
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 First row all columns:', JSON.stringify(result.recordset[0], null, 2));
      console.log('🔍 First row column names:', Object.keys(result.recordset[0]));
    }

    // Kapı listesini map et
    const gates = result.recordset.map((row, index) => {
      // GateID'yi al - kullanıcının verdiği JSON formatına göre: GateID
      const gateId = getValue(row, 'GateID', 'gate_id', 'GateId', 'gateID', 'gateId', 'ID', 'Id', 'id');
      
      const flightCode = getValue(row, 'FlightCode', 'flightCode', 'flight_code');
      const terminal = getValue(row, 'Terminal', 'terminal');
      // GateNo'yu al - kullanıcının verdiği JSON formatına göre: GateNo
      const gateNo = getValue(row, 'GateNo', 'gate_code', 'GateCode', 'gateCode', 'gateNo', 'gate_no');
      const status = getValue(row, 'Status', 'status');
      
      // Yeni alanlar: AirportName, AirlineName
      const airportName = getValue(row, 'AirportName', 'airportName', 'airport_name', 'Airport', 'airport');
      const airlineName = getValue(row, 'AirlineName', 'airlineName', 'airline_name', 'Airline', 'airline', 'AircraftName', 'aircraftName', 'aircraft_name');

      // Debug: İlk satır için detaylı log
      if (index === 0) {
        console.log('🔍 First row all keys:', Object.keys(row));
      }

      // Sadece veritabanından gelen değerleri döndür (kullanıcının istediği format)
      return {
        GateID: gateId || null,
        GateNo: gateNo || null,
        Terminal: terminal || null,
        Status: status || null,
        FlightCode: flightCode || null,
        AirportName: airportName || null,
        AirlineName: airlineName || null,
      };
    });

    console.log('✅ Gates retrieved:', gates.length, 'gates');
    if (gates.length > 0) {
      console.log('📋 Sample gate:', JSON.stringify(gates[0], null, 2));
    }

    res.json({
      success: true,
      data: gates
    });

  } catch (error) {
    console.error('❌ Admin gates error:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: []
    });
  }
});

/**
 * PUT /api/admin/update-gate
 * Kapı bilgilerini günceller
 * FlightReservationSystem.UpdateGate stored procedure'ünü çağırır
 */
router.put('/update-gate', async (req, res) => {
  console.log('📥 PUT /api/admin/update-gate endpoint called');
  console.log('📋 Request body:', req.body);
  
  try {
    const { gateId, gateCode, terminal, status, userId } = req.body;

    // Parametre kontrolü
    if (!gateId || !gateCode || !terminal || !status || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Tüm alanlar zorunludur: gateId, gateCode, terminal, status, userId'
      });
    }

    // Terminal'i parse et: "Terminal A" → "A", "Terminal B" → "B"
    const parseTerminal = (terminalString) => {
      if (!terminalString) return '';
      
      // "Terminal A" formatını parse et
      const trimmed = terminalString.trim();
      
      // Eğer "Terminal " ile başlıyorsa, sonrasını al
      if (trimmed.toLowerCase().startsWith('terminal ')) {
        return trimmed.substring(9).trim(); // "Terminal " (9 karakter) sonrasını al
      }
      
      // Eğer sadece harf varsa (A, B, C gibi), olduğu gibi döndür
      if (trimmed.length <= 2 && /^[A-Z]$/i.test(trimmed)) {
        return trimmed.toUpperCase();
      }
      
      // Diğer durumlarda olduğu gibi döndür
      return trimmed;
    };

    const parsedTerminal = parseTerminal(terminal);
    console.log(`🔍 Terminal parsed: "${terminal}" → "${parsedTerminal}"`);

    const pool = await getPool();

    // Stored procedure'ü çağır
    const request = pool.request();
    request.input('GateID', sql.Int, gateId);
    request.input('GateCode', sql.NVarChar(10), gateCode);
    request.input('Terminal', sql.NVarChar(50), parsedTerminal);
    request.input('Status', sql.NVarChar(20), status);
    request.input('UserID', sql.Int, userId);

    const result = await request.execute('FlightReservationSystem.UpdateGate');

    console.log('✅ Stored procedure executed successfully');
    console.log('📋 Procedure result:', result);

    // Stored procedure başarılı bir şekilde çalıştıysa
    res.json({
      success: true,
      message: 'Kapı başarıyla güncellendi',
      data: {
        gateId,
        gateCode,
        terminal: parsedTerminal,
        status
      }
    });

  } catch (error) {
    console.error('❌ Admin gate update error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

/**
 * DELETE /api/admin/delete-gate
 * Kapıyı siler
 * FlightReservationSystem.DeleteGate stored procedure'ünü çağırır
 */
router.delete('/delete-gate', async (req, res) => {
  console.log('📥 DELETE /api/admin/delete-gate endpoint called');
  console.log('📋 Request body:', req.body);
  
  try {
    const { gateId, userId } = req.body;

    // Parametre kontrolü
    if (!gateId || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Tüm alanlar zorunludur: gateId, userId'
      });
    }

    const pool = await getPool();

    // Stored procedure'ü çağır
    const request = pool.request();
    request.input('GateID', sql.Int, gateId);
    request.input('UserID', sql.Int, userId);

    const result = await request.execute('FlightReservationSystem.DeleteGate');

    console.log('✅ Stored procedure executed successfully');
    console.log('📋 Procedure result:', result);

    // Stored procedure başarılı bir şekilde çalıştıysa
    res.json({
      success: true,
      message: 'Kapı başarıyla silindi',
      data: {
        gateId
      }
    });

  } catch (error) {
    console.error('❌ Admin gate delete error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

/**
 * GET /api/admin/employees
 * Tüm çalışanları döndürür
 * FlightReservationSystem.fn_GetAllEmployees() function'ından alır
 */
router.get('/employees', async (req, res) => {
  console.log('📥 GET /api/admin/employees endpoint called');
  try {
    const pool = await getPool();

    // Çalışan listesini getir
    const result = await pool.request().query(`
      SELECT * FROM FlightReservationSystem.fn_GetAllEmployees()
    `);

    console.log('🔍 Raw database result count:', result.recordset?.length || 0);
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 Sample row keys:', Object.keys(result.recordset[0]));
    }

    if (!result.recordset || result.recordset.length === 0) {
      console.log('⚠️ No employees found in database');
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

    // Debug: İlk satırın tüm kolonlarını logla
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 First row all columns:', JSON.stringify(result.recordset[0], null, 2));
      console.log('🔍 First row column names:', Object.keys(result.recordset[0]));
    }

    // Çalışan listesini map et
    const employees = result.recordset.map((row, index) => {
      const employeeId = getValue(row, 'EmployeeID', 'employee_id', 'EmployeeId', 'employeeID', 'employeeId', 'ID', 'Id', 'id');
      const firstName = getValue(row, 'FirstName', 'firstName', 'first_name', 'Name', 'name');
      const lastName = getValue(row, 'LastName', 'lastName', 'last_name');
      const departmentId = getValue(row, 'DepartmentID', 'departmentID', 'department_id', 'DepartmentId', 'departmentId');
      const departmentName = getValue(row, 'DepartmentName', 'departmentName', 'department_name', 'Name', 'name');
      const salary = getValue(row, 'Salary', 'salary');
      const contact = getValue(row, 'Contact', 'contact');
      const role = getValue(row, 'Role', 'role');

      // Debug: İlk satır için detaylı log
      if (index === 0) {
        console.log('🔍 First row all keys:', Object.keys(row));
      }

      // Sadece veritabanından gelen değerleri döndür
      return {
        EmployeeID: employeeId || null,
        FirstName: firstName || null,
        LastName: lastName || null,
        DepartmentID: departmentId || null,
        DepartmentName: departmentName || null,
        Salary: salary || null,
        Contact: contact || null,
        Role: role || null,
      };
    });

    console.log('✅ Employees retrieved:', employees.length, 'employees');
    if (employees.length > 0) {
      console.log('📋 Sample employee:', JSON.stringify(employees[0], null, 2));
    }

    res.json({
      success: true,
      data: employees
    });

  } catch (error) {
    console.error('❌ Admin employees error:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: []
    });
  }
});

/**
 * PUT /api/admin/update-employee
 * Çalışan bilgilerini günceller
 * FlightReservationSystem.UpdateEmployee stored procedure'ünü çağırır
 */
router.put('/update-employee', async (req, res) => {
  console.log('📥 PUT /api/admin/update-employee endpoint called');
  console.log('📋 Request body:', req.body);
  
  try {
    const { employeeId, firstName, lastName, departmentId, salary, contact, role, userId } = req.body;

    // Parametre kontrolü
    if (!employeeId || !firstName || !lastName || !departmentId || salary === undefined || !contact || !role || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Tüm alanlar zorunludur: employeeId, firstName, lastName, departmentId, salary, contact, role, userId'
      });
    }

    const pool = await getPool();

    // Stored procedure'ü çağır
    const request = pool.request();
    request.input('EmployeeID', sql.Int, employeeId);
    request.input('FirstName', sql.NVarChar(50), firstName);
    request.input('LastName', sql.NVarChar(50), lastName);
    request.input('DepartmentID', sql.Int, departmentId);
    request.input('Salary', sql.Decimal(10, 2), salary);
    request.input('Contact', sql.NVarChar(50), contact);
    request.input('Role', sql.NVarChar(50), role);
    request.input('UserID', sql.Int, userId);

    console.log('🔍 Calling stored procedure with params:', {
      EmployeeID: employeeId,
      FirstName: firstName,
      LastName: lastName,
      DepartmentID: departmentId,
      Salary: salary,
      Contact: contact,
      Role: role,
      UserID: userId
    });

    const result = await request.execute('FlightReservationSystem.UpdateEmployee');

    console.log('✅ Stored procedure executed successfully');
    console.log('📋 Procedure result:', JSON.stringify(result, null, 2));
    console.log('📋 Procedure returnValue:', result.returnValue);
    console.log('📋 Procedure recordset:', result.recordset);
    console.log('📋 Procedure rowsAffected:', result.rowsAffected);

    // Stored procedure başarılı bir şekilde çalıştıysa
    res.json({
      success: true,
      message: 'Çalışan başarıyla güncellendi',
      data: {
        employeeId,
        firstName,
        lastName,
        departmentId,
        salary,
        contact,
        role
      }
    });

  } catch (error) {
    console.error('❌ Admin employee update error:', error);
    console.error('❌ Error name:', error.name);
    console.error('❌ Error message:', error.message);
    console.error('❌ Error stack:', error.stack);
    
    // SQL Server hata mesajını daha detaylı göster
    if (error.originalError) {
      console.error('❌ Original error:', error.originalError);
    }
    if (error.info) {
      console.error('❌ Error info:', error.info);
    }
    
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + (error.message || 'Bilinmeyen hata')
    });
  }
});

/**
 * DELETE /api/admin/delete-employee
 * Çalışanı siler
 * FlightReservationSystem.DeleteEmployee stored procedure'ünü çağırır
 */
router.delete('/delete-employee', async (req, res) => {
  console.log('📥 DELETE /api/admin/delete-employee endpoint called');
  console.log('📋 Request body:', req.body);
  
  try {
    const { employeeId, userId } = req.body;

    // Parametre kontrolü
    if (!employeeId || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Tüm alanlar zorunludur: employeeId, userId'
      });
    }

    const pool = await getPool();

    // Stored procedure'ü çağır
    const request = pool.request();
    request.input('EmployeeID', sql.Int, employeeId);
    request.input('UserID', sql.Int, userId);

    console.log('🔍 Calling stored procedure with params:', {
      EmployeeID: employeeId,
      UserID: userId
    });

    const result = await request.execute('FlightReservationSystem.DeleteEmployee');

    console.log('✅ Stored procedure executed successfully');
    console.log('📋 Procedure result:', JSON.stringify(result, null, 2));
    console.log('📋 Procedure returnValue:', result.returnValue);
    console.log('📋 Procedure recordset:', result.recordset);
    console.log('📋 Procedure rowsAffected:', result.rowsAffected);

    // Stored procedure başarılı bir şekilde çalıştıysa
    res.json({
      success: true,
      message: 'Çalışan başarıyla silindi',
      data: {
        employeeId
      }
    });

  } catch (error) {
    console.error('❌ Admin employee delete error:', error);
    console.error('❌ Error name:', error.name);
    console.error('❌ Error message:', error.message);
    console.error('❌ Error stack:', error.stack);
    
    // SQL Server hata mesajını daha detaylı göster
    if (error.originalError) {
      console.error('❌ Original error:', error.originalError);
    }
    if (error.info) {
      console.error('❌ Error info:', error.info);
    }
    
    // Foreign key constraint hatası kontrolü
    let errorMessage = error.message || 'Bilinmeyen hata';
    if (errorMessage.includes('FK_Departments_Manager') || errorMessage.includes('REFERENCE constraint')) {
      errorMessage = 'Bu çalışan bir departmanın yöneticisi olarak atanmış. Önce departman yöneticisini değiştirmeniz gerekiyor.';
    }
    
    res.status(500).json({
      success: false,
      message: errorMessage
    });
  }
});

/**
 * POST /api/admin/add-employee
 * Yeni çalışan ekler
 * FlightReservationSystem.AddEmployee stored procedure'ünü çağırır
 */
router.post('/add-employee', async (req, res) => {
  console.log('📥 POST /api/admin/add-employee endpoint called');
  console.log('📋 Request body:', req.body);
  
  try {
    const { firstName, lastName, departmentId, salary, contact, role, userId } = req.body;

    // Parametre kontrolü
    if (!firstName || !lastName || !departmentId || salary === undefined || !contact || !role || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Tüm alanlar zorunludur: firstName, lastName, departmentId, salary, contact, role, userId'
      });
    }

    const pool = await getPool();

    // Stored procedure'ü çağır
    const request = pool.request();
    request.input('FirstName', sql.NVarChar(50), firstName);
    request.input('LastName', sql.NVarChar(50), lastName);
    request.input('DepartmentID', sql.Int, departmentId);
    request.input('Salary', sql.Decimal(10, 2), salary);
    request.input('Contact', sql.NVarChar(50), contact);
    request.input('Role', sql.NVarChar(50), role);
    request.input('UserID', sql.Int, userId);

    console.log('🔍 Calling stored procedure with params:', {
      FirstName: firstName,
      LastName: lastName,
      DepartmentID: departmentId,
      Salary: salary,
      Contact: contact,
      Role: role,
      UserID: userId
    });

    const result = await request.execute('FlightReservationSystem.AddEmployee');

    console.log('✅ Stored procedure executed successfully');
    console.log('📋 Procedure result:', JSON.stringify(result, null, 2));
    console.log('📋 Procedure returnValue:', result.returnValue);
    console.log('📋 Procedure recordset:', result.recordset);
    console.log('📋 Procedure rowsAffected:', result.rowsAffected);

    // Stored procedure başarılı bir şekilde çalıştıysa
    res.json({
      success: true,
      message: 'Çalışan başarıyla eklendi',
      data: {
        firstName,
        lastName,
        departmentId,
        salary,
        contact,
        role
      }
    });

  } catch (error) {
    console.error('❌ Admin employee add error:', error);
    console.error('❌ Error name:', error.name);
    console.error('❌ Error message:', error.message);
    console.error('❌ Error stack:', error.stack);
    
    // SQL Server hata mesajını daha detaylı göster
    if (error.originalError) {
      console.error('❌ Original error:', error.originalError);
    }
    if (error.info) {
      console.error('❌ Error info:', error.info);
    }
    
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + (error.message || 'Bilinmeyen hata')
    });
  }
});

/**
 * GET /api/admin/departments
 * Tüm departmanları döndürür
 * FlightReservationSystem.fn_GetAllDepartments() function'ından alır
 */
router.get('/departments', async (req, res) => {
  console.log('📥 GET /api/admin/departments endpoint called');
  try {
    const pool = await getPool();

    // Departman listesini getir
    const result = await pool.request().query(`
      SELECT * FROM FlightReservationSystem.fn_GetAllDepartments()
    `);

    console.log('🔍 Raw database result count:', result.recordset?.length || 0);
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 Sample row keys:', Object.keys(result.recordset[0]));
    }

    if (!result.recordset || result.recordset.length === 0) {
      console.log('⚠️ No departments found in database');
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

    // Debug: İlk satırın tüm kolonlarını logla
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 First row all columns:', JSON.stringify(result.recordset[0], null, 2));
      console.log('🔍 First row column names:', Object.keys(result.recordset[0]));
    }

    // Departman listesini map et
    const departments = result.recordset.map((row, index) => {
      const departmentId = getValue(row, 'DepartmentID', 'department_id', 'DepartmentId', 'departmentID', 'departmentId', 'ID', 'Id', 'id');
      const departmentName = getValue(row, 'DepartmentName', 'departmentName', 'department_name', 'Name', 'name');
      const description = getValue(row, 'Description', 'description');
      const departmentManagerId = getValue(row, 'DepartmentManagerID', 'departmentManagerID', 'department_manager_id', 'ManagerID', 'managerID', 'manager_id');
      const manager = getValue(row, 'Yönetici', 'Manager', 'manager', 'Yonetici', 'yonetici');

      // Debug: İlk satır için detaylı log
      if (index === 0) {
        console.log('🔍 First row all keys:', Object.keys(row));
      }

      // Sadece veritabanından gelen değerleri döndür
      return {
        DepartmentID: departmentId || null,
        DepartmentName: departmentName || null,
        Description: description || null,
        DepartmentManagerID: departmentManagerId || null,
        Manager: manager || null,
      };
    });

    console.log('✅ Departments retrieved:', departments.length, 'departments');
    if (departments.length > 0) {
      console.log('📋 Sample department:', JSON.stringify(departments[0], null, 2));
    }

    res.json({
      success: true,
      data: departments
    });

  } catch (error) {
    console.error('❌ Admin departments error:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: []
    });
  }
});

/**
 * POST /api/admin/add-department
 * Yeni departman ekler
 * FlightReservationSystem.AddDepartment stored procedure'ünü çağırır
 */
router.post('/add-department', async (req, res) => {
  console.log('📥 POST /api/admin/add-department endpoint called');
  console.log('📋 Request body:', req.body);
  
  try {
    const { departmentName, description, departmentManagerId, userId } = req.body;

    // Parametre kontrolü
    if (!departmentName || !description || !departmentManagerId || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Tüm alanlar zorunludur: departmentName, description, departmentManagerId, userId'
      });
    }

    const pool = await getPool();

    // Stored procedure'ü çağır
    const request = pool.request();
    request.input('DepartmentName', sql.NVarChar(100), departmentName);
    request.input('Description', sql.NVarChar(255), description);
    request.input('DepartmentManagerID', sql.Int, departmentManagerId);
    request.input('UserID', sql.Int, userId);

    console.log('🔍 Calling stored procedure with params:', {
      DepartmentName: departmentName,
      Description: description,
      DepartmentManagerID: departmentManagerId,
      UserID: userId
    });

    const result = await request.execute('FlightReservationSystem.AddDepartment');

    console.log('✅ Stored procedure executed successfully');
    console.log('📋 Procedure result:', JSON.stringify(result, null, 2));
    console.log('📋 Procedure returnValue:', result.returnValue);
    console.log('📋 Procedure recordset:', result.recordset);
    console.log('📋 Procedure rowsAffected:', result.rowsAffected);

    // Stored procedure başarılı bir şekilde çalıştıysa
    res.json({
      success: true,
      message: 'Departman başarıyla eklendi',
      data: {
        departmentName,
        description,
        departmentManagerId
      }
    });

  } catch (error) {
    console.error('❌ Admin department add error:', error);
    console.error('❌ Error name:', error.name);
    console.error('❌ Error message:', error.message);
    console.error('❌ Error stack:', error.stack);
    
    // SQL Server hata mesajını daha detaylı göster
    if (error.originalError) {
      console.error('❌ Original error:', error.originalError);
    }
    if (error.info) {
      console.error('❌ Error info:', error.info);
    }
    
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + (error.message || 'Bilinmeyen hata')
    });
  }
});

/**
 * PUT /api/admin/update-department
 * Departman bilgilerini günceller
 * FlightReservationSystem.UpdateDepartment stored procedure'ünü çağırır
 */
router.put('/update-department', async (req, res) => {
  console.log('📥 PUT /api/admin/update-department endpoint called');
  console.log('📋 Request body:', req.body);
  
  try {
    const { departmentId, departmentName, description, departmentManagerId, userId } = req.body;

    // Parametre kontrolü
    if (!departmentId || !departmentName || !description || !departmentManagerId || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Tüm alanlar zorunludur: departmentId, departmentName, description, departmentManagerId, userId'
      });
    }

    const pool = await getPool();

    // Stored procedure'ü çağır
    const request = pool.request();
    request.input('DepartmentID', sql.Int, departmentId);
    request.input('DepartmentName', sql.NVarChar(100), departmentName);
    request.input('Description', sql.NVarChar(255), description);
    request.input('DepartmentManagerID', sql.Int, departmentManagerId);
    request.input('UserID', sql.Int, userId);

    console.log('🔍 Calling stored procedure with params:', {
      DepartmentID: departmentId,
      DepartmentName: departmentName,
      Description: description,
      DepartmentManagerID: departmentManagerId,
      UserID: userId
    });

    const result = await request.execute('FlightReservationSystem.UpdateDepartment');

    console.log('✅ Stored procedure executed successfully');
    console.log('📋 Procedure result:', JSON.stringify(result, null, 2));
    console.log('📋 Procedure returnValue:', result.returnValue);
    console.log('📋 Procedure recordset:', result.recordset);
    console.log('📋 Procedure rowsAffected:', result.rowsAffected);

    // Stored procedure başarılı bir şekilde çalıştıysa
    res.json({
      success: true,
      message: 'Departman başarıyla güncellendi',
      data: {
        departmentId,
        departmentName,
        description,
        departmentManagerId
      }
    });

  } catch (error) {
    console.error('❌ Admin department update error:', error);
    console.error('❌ Error name:', error.name);
    console.error('❌ Error message:', error.message);
    console.error('❌ Error stack:', error.stack);
    
    // SQL Server hata mesajını daha detaylı göster
    if (error.originalError) {
      console.error('❌ Original error:', error.originalError);
    }
    if (error.info) {
      console.error('❌ Error info:', error.info);
    }
    
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + (error.message || 'Bilinmeyen hata')
    });
  }
});

/**
 * DELETE /api/admin/delete-department
 * Departmanı siler
 * FlightReservationSystem.DeleteDepartment stored procedure'ünü çağırır
 */
router.delete('/delete-department', async (req, res) => {
  console.log('📥 DELETE /api/admin/delete-department endpoint called');
  console.log('📋 Request body:', req.body);
  
  try {
    const { departmentId, userId } = req.body;

    // Parametre kontrolü
    if (!departmentId || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Tüm alanlar zorunludur: departmentId, userId'
      });
    }

    const pool = await getPool();

    // Stored procedure'ü çağır
    const request = pool.request();
    request.input('DepartmentID', sql.Int, departmentId);
    request.input('UserID', sql.Int, userId);

    console.log('🔍 Calling stored procedure with params:', {
      DepartmentID: departmentId,
      UserID: userId
    });

    const result = await request.execute('FlightReservationSystem.DeleteDepartment');

    console.log('✅ Stored procedure executed successfully');
    console.log('📋 Procedure result:', JSON.stringify(result, null, 2));
    console.log('📋 Procedure returnValue:', result.returnValue);
    console.log('📋 Procedure recordset:', result.recordset);
    console.log('📋 Procedure rowsAffected:', result.rowsAffected);

    // Stored procedure başarılı bir şekilde çalıştıysa
    res.json({
      success: true,
      message: 'Departman başarıyla silindi',
      data: {
        departmentId
      }
    });

  } catch (error) {
    console.error('❌ Admin department delete error:', error);
    console.error('❌ Error name:', error.name);
    console.error('❌ Error message:', error.message);
    console.error('❌ Error stack:', error.stack);
    
    // SQL Server hata mesajını daha detaylı göster
    if (error.originalError) {
      console.error('❌ Original error:', error.originalError);
    }
    if (error.info) {
      console.error('❌ Error info:', error.info);
    }
    
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + (error.message || 'Bilinmeyen hata')
    });
  }
});

/**
 * GET /api/admin/activity-logs
 * Tüm aktivite loglarını döndürür
 * GeneralCommon.fn_GetActivityLogs() function'ından alır
 */
router.get('/activity-logs', async (req, res) => {
  console.log('📥 GET /api/admin/activity-logs endpoint called');
  try {
    const pool = await getPool();

    // Aktivite loglarını getir
    const result = await pool.request().query(`
      SELECT * FROM GeneralCommon.fn_GetActivityLogs()
    `);

    console.log('🔍 Raw database result count:', result.recordset?.length || 0);
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 Sample row keys:', Object.keys(result.recordset[0]));
    }

    if (!result.recordset || result.recordset.length === 0) {
      console.log('⚠️ No activity logs found in database');
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

    // Debug: İlk satırın tüm kolonlarını logla
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 First row all columns:', JSON.stringify(result.recordset[0], null, 2));
      console.log('🔍 First row column names:', Object.keys(result.recordset[0]));
    }

    // Aktivite loglarını map et
    const logs = result.recordset.map((row, index) => {
      const logId = getValue(row, 'LogID', 'log_id', 'LogId', 'logID', 'logId', 'ID', 'Id', 'id');
      const userName = getValue(row, 'UserName', 'userName', 'user_name', 'Name', 'name');
      const action = getValue(row, 'Action', 'action');
      const description = getValue(row, 'Description', 'description');
      const logDate = getValue(row, 'LogDate', 'logDate', 'log_date', 'Date', 'date');

      // Debug: İlk satır için detaylı log
      if (index === 0) {
        console.log('🔍 First row all keys:', Object.keys(row));
      }

      // Sadece veritabanından gelen değerleri döndür
      return {
        LogID: logId || null,
        UserName: userName || null,
        Action: action || null,
        Description: description || null,
        LogDate: logDate || null,
      };
    });

    console.log('✅ Activity logs retrieved:', logs.length, 'logs');
    if (logs.length > 0) {
      console.log('📋 Sample log:', JSON.stringify(logs[0], null, 2));
    }

    res.json({
      success: true,
      data: logs
    });

  } catch (error) {
    console.error('❌ Admin activity logs error:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: []
    });
  }
});

/**
 * GET /api/admin/reservations
 * Tüm rezervasyonları döndürür
 * FlightReservationSystem.fn_GetAllReservations() function'ından alır
 */
router.get('/reservations', async (req, res) => {
  console.log('📥 GET /api/admin/reservations endpoint called');
  try {
    const pool = await getPool();

    // Rezervasyon listesini getir
    const result = await pool.request().query(`
      SELECT * FROM FlightReservationSystem.fn_GetAllReservations()
    `);

    console.log('🔍 Raw database result count:', result.recordset?.length || 0);
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 Sample row keys:', Object.keys(result.recordset[0]));
    }

    if (!result.recordset || result.recordset.length === 0) {
      console.log('⚠️ No reservations found in database');
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

    // Debug: İlk satırın tüm kolonlarını logla
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 First row all columns:', JSON.stringify(result.recordset[0], null, 2));
      console.log('🔍 First row column names:', Object.keys(result.recordset[0]));
    }

    // Rezervasyon listesini map et
    const reservations = result.recordset.map((row, index) => {
      const reservationId = getValue(row, 'ReservationID', 'reservation_id', 'ReservationId', 'reservationID', 'reservationId', 'ID', 'Id', 'id');
      const reservationCode = getValue(row, 'ReservationCode', 'reservationCode', 'reservation_code');
      const reservationDate = getValue(row, 'ReservationDate', 'reservationDate', 'reservation_date', 'Date', 'date');
      const reservationStatus = getValue(row, 'ReservationStatus', 'reservationStatus', 'reservation_status', 'Status', 'status');
      const totalAmount = getValue(row, 'TotalAmount', 'totalAmount', 'total_amount', 'Amount', 'amount');
      const customerName = getValue(row, 'CustomerName', 'customerName', 'customer_name', 'Name', 'name');
      const email = getValue(row, 'Email', 'email');
      const phone = getValue(row, 'Phone', 'phone');
      const flightId = getValue(row, 'FlightID', 'flightID', 'flight_id', 'FlightId', 'flightId');
      const flightCode = getValue(row, 'FlightCode', 'flightCode', 'flight_code');
      const departureTime = getValue(row, 'DepartureTime', 'departureTime', 'departure_time');
      const arrivalTime = getValue(row, 'ArrivalTime', 'arrivalTime', 'arrival_time');
      const departureAirport = getValue(row, 'DepartureAirport', 'departureAirport', 'departure_airport');
      const arrivalAirport = getValue(row, 'ArrivalAirport', 'arrivalAirport', 'arrival_airport');
      const passengerName = getValue(row, 'PassengerName', 'passengerName', 'passenger_name');
      const seatNumber = getValue(row, 'SeatNumber', 'seatNumber', 'seat_number');
      const ticketNo = getValue(row, 'TicketNo', 'ticketNo', 'ticket_no');
      const flightClass = getValue(row, 'FlightClass', 'flightClass', 'flight_class', 'Class', 'class');
      const paymentMethod = getValue(row, 'PaymentMethod', 'paymentMethod', 'payment_method');
      const passengerCount = getValue(row, 'PassengerCount', 'passengerCount', 'passenger_count');

      // Debug: İlk satır için detaylı log
      if (index === 0) {
        console.log('🔍 First row all keys:', Object.keys(row));
      }

      // Sadece veritabanından gelen değerleri döndür
      return {
        ReservationID: reservationId || null,
        ReservationCode: reservationCode || null,
        ReservationDate: reservationDate || null,
        ReservationStatus: reservationStatus || null,
        TotalAmount: totalAmount || null,
        CustomerName: customerName || null,
        Email: email || null,
        Phone: phone || null,
        FlightID: flightId || null,
        FlightCode: flightCode || null,
        DepartureTime: departureTime || null,
        ArrivalTime: arrivalTime || null,
        DepartureAirport: departureAirport || null,
        ArrivalAirport: arrivalAirport || null,
        PassengerName: passengerName || null,
        SeatNumber: seatNumber || null,
        TicketNo: ticketNo || null,
        FlightClass: flightClass || null,
        PaymentMethod: paymentMethod || null,
        PassengerCount: passengerCount || null,
      };
    });

    console.log('✅ Reservations retrieved:', reservations.length, 'reservations');
    if (reservations.length > 0) {
      console.log('📋 Sample reservation:', JSON.stringify(reservations[0], null, 2));
    }

    res.json({
      success: true,
      data: reservations
    });

  } catch (error) {
    console.error('❌ Admin reservations error:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: []
    });
  }
});

/**
 * DELETE /api/admin/delete-reservation
 * Rezervasyon silme işlemi
 * ERD'ye göre cascade silme: Flight_Tickets -> Flight_Passengers -> Flight_Reservations
 */
router.delete('/delete-reservation', async (req, res) => {
  console.log('📥 DELETE /api/admin/delete-reservation endpoint called');
  const { reservationId, userId } = req.body;

  if (!reservationId || !userId) {
    return res.status(400).json({
      success: false,
      message: 'ReservationID ve UserID gereklidir'
    });
  }

  try {
    const pool = await getPool();
    const request = pool.request();
    
    request.input('ReservationID', sql.Int, reservationId);
    request.input('UserID', sql.Int, userId);

    // Stored procedure'ü çağır
    await request.execute('FlightReservationSystem.DeleteReservation');

    console.log(`✅ Reservation ${reservationId} deleted successfully by user ${userId}`);
    res.json({
      success: true,
      message: 'Rezervasyon başarıyla silindi'
    });

  } catch (error) {
    console.error('❌ Delete reservation error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

/**
 * POST /api/admin/add-reservation
 * Yeni rezervasyon oluşturma işlemi
 * ERD'ye göre: Flight_Reservations -> Flight_Passengers -> Flight_Tickets (opsiyonel)
 */
router.post('/add-reservation', async (req, res) => {
  console.log('📥 POST /api/admin/add-reservation endpoint called');
  const {
    userId,
    flightId,
    reservationDate,
    status = 'Pending',
    totalAmount,
    passengerFirstName,
    passengerLastName,
    passportNo,
    age,
    gender = null,
    nationality = null,
    seatId = null,
    boardingGate = null,
    ticketStatus = 'Confirmed',
    createdByUserId
  } = req.body;

  // Zorunlu alanları kontrol et
  if (!userId || !flightId || !reservationDate || !totalAmount ||
      !passengerFirstName || !passengerLastName || !passportNo || !age || !createdByUserId) {
    return res.status(400).json({
      success: false,
      message: 'Zorunlu alanlar eksik: userId, flightId, reservationDate, totalAmount, passengerFirstName, passengerLastName, passportNo, age, createdByUserId'
    });
  }

  try {
    const pool = await getPool();
    const request = pool.request();
    
    request.input('UserID', sql.Int, userId);
    request.input('FlightID', sql.Int, flightId);
    request.input('ReservationDate', sql.DateTime, new Date(reservationDate));
    request.input('Status', sql.NVarChar(20), status);
    request.input('TotalAmount', sql.Decimal(10, 2), totalAmount);
    request.input('PassengerFirstName', sql.NVarChar(50), passengerFirstName);
    request.input('PassengerLastName', sql.NVarChar(50), passengerLastName);
    request.input('PassportNo', sql.NVarChar(15), passportNo);
    request.input('Age', sql.Int, age);
    request.input('Gender', sql.NVarChar(10), gender);
    request.input('Nationality', sql.NVarChar(50), nationality);
    request.input('SeatID', sql.Int, seatId);
    request.input('BoardingGate', sql.NVarChar(10), boardingGate);
    request.input('TicketStatus', sql.NVarChar(20), ticketStatus);
    request.input('CreatedByUserID', sql.Int, createdByUserId);

    // Stored procedure'ü çağır
    const result = await request.execute('FlightReservationSystem.AddReservation');

    // ReservationID'yi al
    const reservationId = result.recordset?.[0]?.ReservationID;

    console.log(`✅ Reservation ${reservationId} created successfully by user ${createdByUserId}`);
    res.json({
      success: true,
      message: 'Rezervasyon başarıyla oluşturuldu',
      data: {
        reservationId: reservationId
      }
    });

  } catch (error) {
    console.error('❌ Add reservation error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

/**
 * GET /api/admin/passengers
 * Tüm yolcuları getirir
 * ERD'ye göre: Flight_Passengers -> Flight_Reservations -> GeneralCommon_Users -> Flight_Flights -> Flight_Tickets
 */
router.get('/passengers', async (req, res) => {
  console.log('📥 GET /api/admin/passengers endpoint called');
  try {
    const pool = await getPool();
    const request = pool.request();

    // Function'ı çağır
    // Not: Eğer function yoksa, doğrudan query kullanılabilir
    let result;
    try {
      result = await request.query(`
        SELECT * FROM FlightReservationSystem.fn_GetAllPassengers()
        ORDER BY PassengerID DESC
      `);
    } catch (functionError) {
      console.error('❌ Function error, trying direct query:', functionError.message);
      // Function yoksa veya hata varsa, doğrudan query deneyelim
      result = await request.query(`
        SELECT 
          P.PassengerID,
          P.FirstName,
          P.LastName,
          P.PassportNo,
          P.Age,
          P.Gender,
          P.Nationality,
          P.ReservationID,
          NULL AS ReservationCode,
          NULL AS ReservationDate,
          NULL AS ReservationStatus,
          NULL AS TotalAmount,
          NULL AS CustomerUserID,
          NULL AS CustomerName,
          NULL AS CustomerEmail,
          NULL AS CustomerPhone,
          NULL AS FlightID,
          NULL AS FlightCode,
          NULL AS DepartureTime,
          NULL AS ArrivalTime,
          NULL AS DepartureAirport,
          NULL AS ArrivalAirport,
          NULL AS TicketID,
          NULL AS BoardingGate,
          NULL AS TicketStatus,
          NULL AS SeatID,
          NULL AS SeatNumber,
          NULL AS ClassID,
          NULL AS FlightClass
        FROM FlightReservationSystem.Passengers P
        ORDER BY P.PassengerID DESC
      `);
    }

    console.log('🔍 Raw database result count:', result.recordset?.length || 0);
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 Sample row keys:', Object.keys(result.recordset[0]));
    }

    if (!result.recordset || result.recordset.length === 0) {
      console.log('⚠️ No passengers found in database');
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

    // Debug: İlk satırın tüm kolonlarını logla
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 First row all columns:', JSON.stringify(result.recordset[0], null, 2));
      console.log('🔍 First row column names:', Object.keys(result.recordset[0]));
    }

    // Yolcu listesini map et
    const passengers = result.recordset.map((row, index) => {
      const passengerId = getValue(row, 'PassengerID', 'passenger_id', 'PassengerId', 'passengerID', 'passengerId', 'ID', 'Id', 'id');
      const firstName = getValue(row, 'FirstName', 'firstName', 'first_name', 'Name', 'name');
      const lastName = getValue(row, 'LastName', 'lastName', 'last_name');
      const passportNo = getValue(row, 'PassportNo', 'passportNo', 'passport_no', 'PassportNumber', 'passportNumber');
      const age = getValue(row, 'Age', 'age');
      const gender = getValue(row, 'Gender', 'gender');
      const nationality = getValue(row, 'Nationality', 'nationality');
      const reservationId = getValue(row, 'ReservationID', 'reservationID', 'reservation_id', 'ReservationId', 'reservationId');
      const reservationCode = getValue(row, 'ReservationCode', 'reservationCode', 'reservation_code');
      const reservationDate = getValue(row, 'ReservationDate', 'reservationDate', 'reservation_date');
      const reservationStatus = getValue(row, 'ReservationStatus', 'reservationStatus', 'reservation_status');
      const totalAmount = getValue(row, 'TotalAmount', 'totalAmount', 'total_amount');
      const customerUserId = getValue(row, 'CustomerUserID', 'customerUserID', 'customer_user_id', 'CustomerUserId', 'customerUserId');
      const customerName = getValue(row, 'CustomerName', 'customerName', 'customer_name');
      const customerEmail = getValue(row, 'CustomerEmail', 'customerEmail', 'customer_email', 'Email', 'email');
      const customerPhone = getValue(row, 'CustomerPhone', 'customerPhone', 'customer_phone', 'Phone', 'phone');
      const flightId = getValue(row, 'FlightID', 'flightID', 'flight_id', 'FlightId', 'flightId');
      const flightCode = getValue(row, 'FlightCode', 'flightCode', 'flight_code');
      const departureTime = getValue(row, 'DepartureTime', 'departureTime', 'departure_time');
      const arrivalTime = getValue(row, 'ArrivalTime', 'arrivalTime', 'arrival_time');
      const departureAirport = getValue(row, 'DepartureAirport', 'departureAirport', 'departure_airport');
      const arrivalAirport = getValue(row, 'ArrivalAirport', 'arrivalAirport', 'arrival_airport');
      const ticketId = getValue(row, 'TicketID', 'ticketID', 'ticket_id', 'TicketId', 'ticketId');
      const boardingGate = getValue(row, 'BoardingGate', 'boardingGate', 'boarding_gate');
      const ticketStatus = getValue(row, 'TicketStatus', 'ticketStatus', 'ticket_status');
      const seatId = getValue(row, 'SeatID', 'seatID', 'seat_id', 'SeatId', 'seatId');
      const seatNumber = getValue(row, 'SeatNumber', 'seatNumber', 'seat_number');
      const classId = getValue(row, 'ClassID', 'classID', 'class_id', 'ClassId', 'classId');
      const flightClass = getValue(row, 'FlightClass', 'flightClass', 'flight_class', 'Class', 'class');

      return {
        PassengerID: passengerId || null,
        FirstName: firstName || null,
        LastName: lastName || null,
        PassportNo: passportNo || null,
        Age: age || null,
        Gender: gender || null,
        Nationality: nationality || null,
        ReservationID: reservationId || null,
        ReservationCode: reservationCode || null,
        ReservationDate: reservationDate || null,
        ReservationStatus: reservationStatus || null,
        TotalAmount: totalAmount || null,
        CustomerUserID: customerUserId || null,
        CustomerName: customerName || null,
        CustomerEmail: customerEmail || null,
        CustomerPhone: customerPhone || null,
        FlightID: flightId || null,
        FlightCode: flightCode || null,
        DepartureTime: departureTime || null,
        ArrivalTime: arrivalTime || null,
        DepartureAirport: departureAirport || null,
        ArrivalAirport: arrivalAirport || null,
        TicketID: ticketId || null,
        BoardingGate: boardingGate || null,
        TicketStatus: ticketStatus || null,
        SeatID: seatId || null,
        SeatNumber: seatNumber || null,
        ClassID: classId || null,
        FlightClass: flightClass || null,
      };
    });

    console.log('✅ Passengers retrieved:', passengers.length, 'passengers');
    if (passengers.length > 0) {
      console.log('📋 Sample passenger:', JSON.stringify(passengers[0], null, 2));
    }

    res.json({
      success: true,
      data: passengers
    });

  } catch (error) {
    console.error('❌ Admin passengers error:', error);
    console.error('❌ Error message:', error.message);
    console.error('❌ Error stack:', error.stack);
    
    // SQL hatası detaylarını logla
    if (error.number) {
      console.error('❌ SQL Error Number:', error.number);
    }
    if (error.originalError) {
      console.error('❌ Original Error:', error.originalError);
    }
    
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + (error.message || 'Bilinmeyen hata'),
      data: []
    });
  }
});

/**
 * PUT /api/admin/update-passenger
 * Yolcu bilgilerini günceller
 * FlightReservationSystem.UpdatePassenger stored procedure'ünü çağırır
 */
router.put('/update-passenger', async (req, res) => {
  console.log('📥 PUT /api/admin/update-passenger endpoint called');
  console.log('📋 Request body:', JSON.stringify(req.body, null, 2));

  try {
    const {
      passengerId,
      firstName,
      lastName,
      passportNo,
      age,
      gender,
      nationality,
      userId
    } = req.body;

    // Validasyon
    if (!passengerId || !firstName || !lastName || !passportNo || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Eksik parametreler: passengerId, firstName, lastName, passportNo ve userId zorunludur.'
      });
    }

    const pool = await getPool();
    const request = pool.request();

    // Stored procedure parametrelerini ekle
    request.input('PassengerID', sql.Int, passengerId);
    request.input('FirstName', sql.NVarChar(50), firstName);
    request.input('LastName', sql.NVarChar(50), lastName);
    request.input('PassportNo', sql.NVarChar(20), passportNo);
    request.input('Age', sql.Int, age || null);
    request.input('Gender', sql.NVarChar(10), gender || null);
    request.input('Nationality', sql.NVarChar(50), nationality || null);
    request.input('UserID', sql.Int, userId);

    // Stored procedure'ü çağır
    await request.execute('FlightReservationSystem.UpdatePassenger');

    console.log(`✅ Passenger ${passengerId} updated successfully by user ${userId}`);
    res.json({
      success: true,
      message: 'Yolcu bilgileri başarıyla güncellendi'
    });

  } catch (error) {
    console.error('❌ Update passenger error:', error);
    
    // Özel hata mesajlarını kontrol et
    let errorMessage = 'Sunucu hatası: ' + error.message;
    if (error.message && error.message.includes('Yolcu bulunamadı')) {
      errorMessage = 'Yolcu bulunamadı.';
    } else if (error.message && error.message.includes('pasaport numarası')) {
      errorMessage = 'Bu pasaport numarası başka bir yolcu tarafından kullanılıyor.';
    }

    res.status(500).json({
      success: false,
      message: errorMessage
    });
  }
});

/**
 * POST /api/admin/add-passenger
 * Yeni yolcu ekler
 * FlightReservationSystem.AddPassenger stored procedure'ünü çağırır
 * ERD'ye göre: ReservationID FK kontrolü ve PassportNo unique kontrolü yapılır
 */
router.post('/add-passenger', async (req, res) => {
  console.log('📥 POST /api/admin/add-passenger endpoint called');
  console.log('📋 Request body:', JSON.stringify(req.body, null, 2));

  try {
    const {
      reservationId,
      firstName,
      lastName,
      passportNo,
      age,
      gender,
      nationality,
      userId
    } = req.body;

    // Validasyon
    if (!reservationId || !firstName || !lastName || !passportNo || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Eksik parametreler: reservationId, firstName, lastName, passportNo ve userId zorunludur.'
      });
    }

    const pool = await getPool();
    const request = pool.request();

    // Stored procedure parametrelerini ekle
    request.input('ReservationID', sql.Int, reservationId);
    request.input('FirstName', sql.NVarChar(50), firstName);
    request.input('LastName', sql.NVarChar(50), lastName);
    request.input('PassportNo', sql.NVarChar(20), passportNo);
    request.input('Age', sql.Int, age || null);
    request.input('Gender', sql.NVarChar(10), gender || null);
    request.input('Nationality', sql.NVarChar(50), nationality || null);
    request.input('UserID', sql.Int, userId);

    // Stored procedure'ü çağır
    const result = await request.execute('FlightReservationSystem.AddPassenger');

    // PassengerID'yi al
    const passengerId = result.recordset?.[0]?.PassengerID;

    console.log(`✅ Passenger ${passengerId} created successfully by user ${userId}`);
    res.json({
      success: true,
      message: 'Yolcu başarıyla eklendi',
      data: {
        passengerId: passengerId
      }
    });

  } catch (error) {
    console.error('❌ Add passenger error:', error);
    
    // Özel hata mesajlarını kontrol et
    let errorMessage = 'Sunucu hatası: ' + error.message;
    if (error.message && error.message.includes('Rezervasyon bulunamadı')) {
      errorMessage = 'Rezervasyon bulunamadı.';
    } else if (error.message && error.message.includes('pasaport numarası')) {
      errorMessage = 'Bu pasaport numarası zaten kullanılıyor.';
    }

    res.status(500).json({
      success: false,
      message: errorMessage
    });
  }
});

/**
 * DELETE /api/admin/delete-passenger
 * Yolcuyu siler
 * FlightReservationSystem.DeletePassenger stored procedure'ünü çağırır
 * ERD'ye göre: Önce Flight_Tickets'taki ticket'ları siler, sonra yolcuyu siler
 */
router.delete('/delete-passenger', async (req, res) => {
  console.log('📥 DELETE /api/admin/delete-passenger endpoint called');
  console.log('📋 Request body:', JSON.stringify(req.body, null, 2));

  try {
    const { passengerId, userId } = req.body;

    // Validasyon
    if (!passengerId || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Eksik parametreler: passengerId ve userId zorunludur.'
      });
    }

    const pool = await getPool();
    const request = pool.request();

    // Stored procedure parametrelerini ekle
    request.input('PassengerID', sql.Int, passengerId);
    request.input('UserID', sql.Int, userId);

    // Stored procedure'ü çağır
    await request.execute('FlightReservationSystem.DeletePassenger');

    console.log(`✅ Passenger ${passengerId} deleted successfully by user ${userId}`);
    res.json({
      success: true,
      message: 'Yolcu başarıyla silindi'
    });

  } catch (error) {
    console.error('❌ Delete passenger error:', error);
    
    // Özel hata mesajlarını kontrol et
    let errorMessage = 'Sunucu hatası: ' + error.message;
    if (error.message && error.message.includes('Yolcu bulunamadı')) {
      errorMessage = 'Yolcu bulunamadı.';
    } else if (error.message && error.message.includes('FOREIGN KEY constraint')) {
      errorMessage = 'Bu yolcunun bağlı kayıtları olduğu için silinemiyor.';
    }

    res.status(500).json({
      success: false,
      message: errorMessage
    });
  }
});

/**
 * GET /api/admin/vehicle-types
 * Tüm araç tiplerini getirir
 * AirportParkingSystem.fn_GetAllVehicleTypes() function'ından alır
 */
router.get('/vehicle-types', async (req, res) => {
  console.log('📥 GET /api/admin/vehicle-types endpoint called');
  try {
    const pool = await getPool();
    const request = pool.request();

    // Function'ı çağır
    const result = await request.query(`
      SELECT * FROM AirportParkingSystem.fn_GetAllVehicleTypes()
      ORDER BY TypeID ASC
    `);

    console.log('🔍 Raw database result count:', result.recordset?.length || 0);
    if (result.recordset && result.recordset.length > 0) {
      console.log('🔍 Sample row keys:', Object.keys(result.recordset[0]));
    }

    if (!result.recordset || result.recordset.length === 0) {
      console.log('⚠️ No vehicle types found in database');
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

    // Araç tipi listesini map et
    const vehicleTypes = result.recordset.map((row) => {
      const typeId = getValue(row, 'TypeID', 'typeID', 'type_id', 'TypeId', 'typeId', 'ID', 'Id', 'id');
      const typeName = getValue(row, 'TypeName', 'typeName', 'type_name', 'Name', 'name');
      const priceMultiplier = getValue(row, 'PriceMultiplier', 'priceMultiplier', 'price_multiplier', 'Multiplier', 'multiplier');

      return {
        TypeID: typeId || null,
        TypeName: typeName || null,
        PriceMultiplier: priceMultiplier != null ? parseFloat(priceMultiplier) : null,
      };
    });

    console.log('✅ Vehicle types retrieved:', vehicleTypes.length, 'types');
    if (vehicleTypes.length > 0) {
      console.log('📋 Sample vehicle type:', JSON.stringify(vehicleTypes[0], null, 2));
    }

    res.json({
      success: true,
      data: vehicleTypes
    });

  } catch (error) {
    console.error('❌ Admin vehicle-types error:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: []
    });
  }
});

module.exports = router;


