const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

async function verifyConnection() {
  const connection = await pool.getConnection();
  await connection.ping();
  connection.release();
}

async function ensureDatabaseArtifacts() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS user_credentials (
      user_id VARCHAR(64) PRIMARY KEY,
      password_hash VARCHAR(255) NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);
}

module.exports = {
  pool,
  verifyConnection,
  ensureDatabaseArtifacts,
};
