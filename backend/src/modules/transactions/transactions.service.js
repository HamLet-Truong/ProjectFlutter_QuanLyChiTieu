const { randomUUID } = require('crypto');
const { pool } = require('../../config/db');

async function listTransactions(userId) {
  const [rows] = await pool.query(
    `SELECT id, amount, date, note, type, categoryId, userId
     FROM transactions
     WHERE userId = ?
     ORDER BY date DESC`,
    [userId]
  );
  return rows;
}

async function createTransaction(userId, payload) {
  const tx = {
    id: randomUUID(),
    amount: Number(payload.amount),
    date: payload.date || new Date().toISOString(),
    note: payload.note || '',
    type: payload.type,
    categoryId: payload.categoryId,
    userId,
  };

  await pool.query(
    `INSERT INTO transactions (id, amount, date, note, type, categoryId, userId)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [tx.id, tx.amount, tx.date, tx.note, tx.type, tx.categoryId, tx.userId]
  );

  return tx;
}

async function updateTransaction(userId, id, payload) {
  await pool.query(
    `UPDATE transactions
     SET amount = ?, date = ?, note = ?, type = ?, categoryId = ?
     WHERE id = ? AND userId = ?`,
    [
      Number(payload.amount),
      payload.date,
      payload.note || '',
      payload.type,
      payload.categoryId,
      id,
      userId,
    ]
  );

  const [rows] = await pool.query(
    'SELECT id, amount, date, note, type, categoryId, userId FROM transactions WHERE id = ? AND userId = ? LIMIT 1',
    [id, userId]
  );

  if (rows.length === 0) {
    const error = new Error('Transaction not found');
    error.statusCode = 404;
    throw error;
  }

  return rows[0];
}

async function deleteTransaction(userId, id) {
  const [result] = await pool.query('DELETE FROM transactions WHERE id = ? AND userId = ?', [id, userId]);
  if (result.affectedRows === 0) {
    const error = new Error('Transaction not found');
    error.statusCode = 404;
    throw error;
  }
}

module.exports = {
  listTransactions,
  createTransaction,
  updateTransaction,
  deleteTransaction,
};
