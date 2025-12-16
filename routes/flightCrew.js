const express = require('express');
const router = express.Router();
const { getPool, sql } = require('../config/database');

router.get('/list', async (req, res) => {
  try {
    const pool = await getPool();
    // --- Manual Override Candidate based on known schema ---
    // FlightCrew has Role string, not RoleID.
    // Flights has AirlineID, not FlightNo.
    // Airports has IATA_Code.
    // Employees has FirstName, LastName.
    const knownSchemaQuery = `
      SELECT
        fc.CrewID,
        CONCAT(al.Name, ' ', f.FlightID, ' - ', dep.IATA_Code, ' → ', arr.IATA_Code) AS Flight,
        CONCAT(e.FirstName, ' ', e.LastName) AS Employee,
        fc.EmployeeID,
        fc.Role AS Role
      FROM FlightReservationSystem.FlightCrew fc
      JOIN FlightReservationSystem.Flights f ON fc.FlightID = f.FlightID
      JOIN FlightReservationSystem.Employees e ON fc.EmployeeID = e.EmployeeID
      JOIN FlightReservationSystem.Airports dep ON f.DepartureAirportID = dep.AirportID
      JOIN FlightReservationSystem.Airports arr ON f.ArrivalAirportID = arr.AirportID
      LEFT JOIN FlightReservationSystem.Airlines al ON f.AirlineID = al.AirlineID
      ORDER BY fc.CrewID DESC
    `;

    try {
      const result = await pool.request().query(knownSchemaQuery);
      if (result.recordset && result.recordset.length > 0) {
        const rows = result.recordset.map(row => ({
          crewID: row.CrewID,
          flight: row.Flight,
          employee: row.Employee,
          employeeID: row.EmployeeID,
          role: row.Role
        }));
        return res.json({ success: true, data: rows });
      }
    } catch (e) {
      console.log('Known schema query failed, trying dynamic detection:', e.message);
    }

      const candidates = [
        `SELECT 
           fc.CrewID,
           CONCAT(f.FlightNo, ' - ', dep.Code, ' → ', arr.Code) AS Flight,
           e.FullName AS Employee,
           r.RoleName AS Role
         FROM FlightReservationSystem.FlightCrew fc
         JOIN FlightReservationSystem.Flights f ON fc.FlightID = f.FlightID
         JOIN GeneralCommon.Employees e ON fc.EmployeeID = e.EmployeeID
         JOIN GeneralCommon.Roles r ON fc.RoleID = r.RoleID
         JOIN FlightReservationSystem.Airports dep ON f.DepartureAirportID = dep.AirportID
         JOIN FlightReservationSystem.Airports arr ON f.ArrivalAirportID = arr.AirportID
         ORDER BY fc.CrewID DESC`,
        `SELECT 
           fc.CrewID,
           CONCAT(f.FlightNo, ' - ', dep.Code, ' → ', arr.Code) AS Flight,
           COALESCE(e.FullName, CONCAT(e.FirstName, ' ', e.LastName)) AS Employee,
           r.RoleName AS Role
         FROM dbo.FlightCrew fc
         JOIN dbo.Flights f ON fc.FlightID = f.FlightID
         JOIN dbo.Airports dep ON f.DepartureAirportID = dep.AirportID
         JOIN dbo.Airports arr ON f.ArrivalAirportID = arr.AirportID
         JOIN dbo.Employees e ON fc.EmployeeID = e.EmployeeID
         JOIN dbo.Roles r ON fc.RoleID = r.RoleID
         ORDER BY fc.CrewID DESC`,
        `SELECT 
           fc.CrewID,
           CONCAT(f.FlightNo, ' - ', dep.Code, ' → ', arr.Code) AS Flight,
           e.FullName AS Employee,
           r.RoleName AS Role
         FROM AirportServices.dbo.FlightCrew fc
         JOIN AirportServices.dbo.Flights f ON fc.FlightID = f.FlightID
         JOIN AirportServices.dbo.Airports dep ON f.DepartureAirportID = dep.AirportID
         JOIN AirportServices.dbo.Airports arr ON f.ArrivalAirportID = arr.AirportID
         JOIN AirportServices.dbo.Employees e ON fc.EmployeeID = e.EmployeeID
         JOIN AirportServices.dbo.Roles r ON fc.RoleID = r.RoleID
         ORDER BY fc.CrewID DESC`
      ];
      for (const q of candidates) {
        try {
          const res2 = await pool.request().query(q);
          if (res2 && res2.recordset) {
            const rows2 = res2.recordset.map(row => ({
              crewID: row.CrewID,
              flight: row.Flight,
              employee: row.Employee,
              role: row.Role
            }));
            return res.json({ success: true, data: rows2 });
          }
        } catch (_) {}
      }
      return res.json({
        success: true,
        data: []
      });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message,
      data: []
    });
  }
});

router.get('/flights', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT 
        f.FlightID, 
        CONCAT(al.Name, ' ', f.FlightID, ' - ', dep.IATA_Code, ' → ', arr.IATA_Code) as Label 
      FROM FlightReservationSystem.Flights f 
      LEFT JOIN FlightReservationSystem.Airlines al ON f.AirlineID = al.AirlineID
      JOIN FlightReservationSystem.Airports dep ON f.DepartureAirportID = dep.AirportID
      JOIN FlightReservationSystem.Airports arr ON f.ArrivalAirportID = arr.AirportID
      ORDER BY f.FlightID DESC
    `);
    res.json({ success: true, data: result.recordset });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get('/employees', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT EmployeeID, CONCAT(FirstName, ' ', LastName) as Name 
      FROM FlightReservationSystem.Employees
      ORDER BY FirstName, LastName
    `);
    res.json({ success: true, data: result.recordset });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get('/roles', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT RoleName 
      FROM GeneralCommon.Roles
      ORDER BY RoleName
    `);
    res.json({ success: true, data: result.recordset });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/add', async (req, res) => {
  try {
    const pool = await getPool();
    const { flightID, employeeID, role } = req.body;
    
    if (!flightID || !employeeID || !role) {
      return res.status(400).json({ success: false, message: 'Missing fields' });
    }

    await pool.request()
      .input('flightID', sql.Int, flightID)
      .input('employeeID', sql.Int, employeeID)
      .input('role', sql.NVarChar, role)
      .query(`
        INSERT INTO FlightReservationSystem.FlightCrew (FlightID, EmployeeID, Role)
        VALUES (@flightID, @employeeID, @role)
      `);
      
    res.json({ success: true, message: 'Crew added successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.delete('/delete-by-employee/:id', async (req, res) => {
  try {
    const pool = await getPool();
    const id = parseInt(req.params.id);
    
    if (!id) {
      return res.status(400).json({ success: false, message: 'Invalid ID' });
    }

    // Try deleting from the known schema first
    try {
      await pool.request()
        .input('id', sql.Int, id)
        .query('DELETE FROM FlightReservationSystem.FlightCrew WHERE EmployeeID = @id');
        
      return res.json({ success: true, message: 'Deleted successfully' });
    } catch (err) {
      console.log('Primary delete failed, trying fallback schemas:', err.message);
      
      // Fallback schemas
      const candidates = [
        'DELETE FROM dbo.FlightCrew WHERE EmployeeID = @id',
        'DELETE FROM AirportServices.dbo.FlightCrew WHERE EmployeeID = @id'
      ];
      
      for (const q of candidates) {
        try {
          await pool.request().input('id', sql.Int, id).query(q);
          return res.json({ success: true, message: 'Deleted successfully' });
        } catch (_) {}
      }
      
      throw err; // If all fail
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error: ' + error.message
    });
  }
});

module.exports = router;
