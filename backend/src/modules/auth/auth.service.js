const bcrypt = require('bcryptjs');
const { randomUUID } = require('crypto');
const { pool } = require('../../config/db');
const { signToken } = require('../../utils/token');

async function register({ name, email, password }) {
  const [existingUsers] = await pool.query('SELECT id FROM users WHERE email = ? LIMIT 1', [email]);
  if (existingUsers.length > 0) {
    const error = new Error('Email already exists');
    error.statusCode = 409;
    throw error;
  }

  const userId = randomUUID();
  const passwordHash = await bcrypt.hash(password, 10);

  await pool.query(
    'INSERT INTO users (id, name, email, preferredCurrency, createdAt) VALUES (?, ?, ?, ?, ?)',
    [userId, name, email, 'VND', new Date().toISOString()]
  );

  await pool.query(
    'INSERT INTO user_credentials (user_id, password_hash) VALUES (?, ?)',
    [userId, passwordHash]
  );

  const token = signToken({ userId, email });

  return {
    token,
    user: {
      id: userId,
      name,
      email,
      preferredCurrency: 'VND',
    },
  };
}

async function login({ email, password }) {
  const [rows] = await pool.query(
    `SELECT u.id, u.name, u.email, u.preferredCurrency, c.password_hash
     FROM users u
     INNER JOIN user_credentials c ON c.user_id = u.id
     WHERE u.email = ?
     LIMIT 1`,
    [email]
  );

  if (rows.length === 0) {
    const error = new Error('Invalid credentials');
    error.statusCode = 401;
    throw error;
  }

  const user = rows[0];
  const isValid = await bcrypt.compare(password, user.password_hash);
  if (!isValid) {
    const error = new Error('Invalid credentials');
    error.statusCode = 401;
    throw error;
  }

  const token = signToken({ userId: user.id, email: user.email });

  return {
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      preferredCurrency: user.preferredCurrency,
    },
  };
}

async function getMe(userId) {
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

module.exports = {
  register,
  login,
  getMe,
};
