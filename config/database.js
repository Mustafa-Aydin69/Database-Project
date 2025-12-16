const sql = require('mssql');

const dbConfig = {
  server: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '1433'),
  database: process.env.DB_NAME || 'AirportServices',
  user: process.env.DB_USER || 'sa',
  password: process.env.DB_PASSWORD || '16311814',
  options: {
    encrypt: process.env.DB_ENCRYPT === 'true', // Azure/AWS RDS için true, local için false
    trustServerCertificate: true, // Local development için
    enableArithAbort: true,
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  }
};

let pool = null;

// Veritabanı bağlantı pool'unu oluştur
async function getPool() {
  if (!pool) {
    try {
      pool = await sql.connect(dbConfig);
      console.log('✅ Database connection pool created successfully');
      console.log(`📊 Connected to: ${dbConfig.server}:${dbConfig.port}/${dbConfig.database}`);
      return pool;
    } catch (err) {
      console.error('❌ Database connection error:', err);
      throw err;
    }
  }
  return pool;
}

// Bağlantıyı kapat
async function closePool() {
  if (pool) {
    await pool.close();
    pool = null;
    console.log('🔒 Database connection pool closed');
  }
}

module.exports = {
  getPool,
  closePool,
  sql
};



