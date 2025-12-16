const express = require('express');
const router = express.Router();
const { getPool, sql } = require('../config/database');

// --- DEBUG SCHEMA ---
router.get('/debug-schema', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = 'FlightReservationSystem' 
      AND TABLE_NAME = 'FlightPricing'
    `);
    res.json({ success: true, data: result.recordset });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// --- GET ALL PRICES ---
router.get('/list', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT 
        fp.PriceID,
        fp.FlightID,
        fp.ClassID,
        fp.Price,
        fc.ClassName,
        CONCAT(al.Name, ' ', f.FlightID, ' - ', dep.IATA_Code, ' → ', arr.IATA_Code) as FlightLabel
      FROM FlightReservationSystem.FlightPricing fp
      JOIN FlightReservationSystem.Flights f ON fp.FlightID = f.FlightID
      JOIN FlightReservationSystem.Flight_Classes fc ON fp.ClassID = fc.ClassID
      LEFT JOIN FlightReservationSystem.Airlines al ON f.AirlineID = al.AirlineID
      JOIN FlightReservationSystem.Airports dep ON f.DepartureAirportID = dep.AirportID
      JOIN FlightReservationSystem.Airports arr ON f.ArrivalAirportID = arr.AirportID
      ORDER BY fp.PriceID DESC
    `);
    
    const rows = result.recordset.map(row => ({
      pricingID: row.PriceID, // Frontend expects pricingID
      flightID: row.FlightID,
      classID: row.ClassID,
      price: row.Price,
      className: row.ClassName,
      flightLabel: row.FlightLabel
    }));

    res.json({ success: true, data: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// --- GET FLIGHTS DROPDOWN ---
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

// --- GET CLASSES DROPDOWN ---
router.get('/classes', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT ClassID, ClassName
      FROM FlightReservationSystem.Flight_Classes
      ORDER BY ClassID
    `);
    res.json({ success: true, data: result.recordset });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// --- ADD PRICE ---
router.post('/add', async (req, res) => {
  try {
    const pool = await getPool();
    const { flightID, classID, price } = req.body;

    if (!flightID || !classID || !price) {
      return res.status(400).json({ success: false, message: 'Missing fields' });
    }

    await pool.request()
      .input('flightID', sql.Int, flightID)
      .input('classID', sql.Int, classID)
      .input('price', sql.Decimal(10, 2), price)
      .query(`
        INSERT INTO FlightReservationSystem.FlightPricing (FlightID, ClassID, Price)
        VALUES (@flightID, @classID, @price)
      `);

    res.json({ success: true, message: 'Price added successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// --- UPDATE PRICE ---
router.put('/update/:id', async (req, res) => {
  try {
    const pool = await getPool();
    const id = parseInt(req.params.id);
    const { flightID, classID, price } = req.body;

    if (!id || !flightID || !classID || !price) {
      return res.status(400).json({ success: false, message: 'Missing fields' });
    }

    await pool.request()
      .input('id', sql.Int, id)
      .input('flightID', sql.Int, flightID)
      .input('classID', sql.Int, classID)
      .input('price', sql.Decimal(10, 2), price)
      .query(`
        UPDATE FlightReservationSystem.FlightPricing
        SET FlightID = @flightID, ClassID = @classID, Price = @price
        WHERE PriceID = @id
      `);

    res.json({ success: true, message: 'Price updated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// --- DELETE PRICE ---
router.delete('/delete/:id', async (req, res) => {
  try {
    const pool = await getPool();
    const id = parseInt(req.params.id);

    if (!id) {
      return res.status(400).json({ success: false, message: 'Invalid ID' });
    }

    await pool.request()
      .input('id', sql.Int, id)
      .query('DELETE FROM FlightReservationSystem.FlightPricing WHERE PriceID = @id');

    res.json({ success: true, message: 'Price deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
