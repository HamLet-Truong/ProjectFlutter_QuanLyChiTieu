const { pool } = require('../../config/db');

async function getProfile(userId) {
  const [rows] = await pool.query(
    'SELECT id, name, email, preferredCurrency, createdAt FROM users WHERE id = ? LIMIT 1',
    [userId]
  );

  if (rows.length === 0) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }

  return rows[0];
}

async function updateProfile(userId, { name, email }) {
  await pool.query('UPDATE users SET name = ?, email = ? WHERE id = ?', [name, email, userId]);
  return getProfile(userId);
}

module.exports = {
  getProfile,
  updateProfile,
};
