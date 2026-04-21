const { randomUUID } = require('crypto');
const { pool } = require('../../config/db');

async function listBudgets() {
  const [rows] = await pool.query(
    'SELECT id, categoryId, limitAmount, startDate, endDate FROM budgets ORDER BY startDate DESC'
  );
  return rows;
}

async function createBudget(payload) {
  const budget = {
    id: randomUUID(),
    categoryId: payload.categoryId,
    limitAmount: Number(payload.limitAmount),
    startDate: payload.startDate,
    endDate: payload.endDate,
  };

  await pool.query(
    'INSERT INTO budgets (id, categoryId, limitAmount, startDate, endDate) VALUES (?, ?, ?, ?, ?)',
    [budget.id, budget.categoryId, budget.limitAmount, budget.startDate, budget.endDate]
  );

  return budget;
}

async function updateBudget(id, payload) {
  await pool.query(
    'UPDATE budgets SET categoryId = ?, limitAmount = ?, startDate = ?, endDate = ? WHERE id = ?',
    [payload.categoryId, Number(payload.limitAmount), payload.startDate, payload.endDate, id]
  );

  const [rows] = await pool.query(
    'SELECT id, categoryId, limitAmount, startDate, endDate FROM budgets WHERE id = ? LIMIT 1',
    [id]
  );

  if (rows.length === 0) {
    const error = new Error('Budget not found');
    error.statusCode = 404;
    throw error;
  }

  return rows[0];
}

async function deleteBudget(id) {
  const [result] = await pool.query('DELETE FROM budgets WHERE id = ?', [id]);
  if (result.affectedRows === 0) {
    const error = new Error('Budget not found');
    error.statusCode = 404;
    throw error;
  }
}

module.exports = {
  listBudgets,
  createBudget,
  updateBudget,
  deleteBudget,
};
