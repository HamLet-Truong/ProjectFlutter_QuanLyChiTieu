const { pool } = require('../../config/db');

async function getSummary(userId) {
  const [incomeRows] = await pool.query(
    'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE userId = ? AND type = ? ',
    [userId, 'income']
  );
  const [expenseRows] = await pool.query(
    'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE userId = ? AND type = ? ',
    [userId, 'expense']
  );

  const income = Number(incomeRows[0]?.total || 0);
  const expense = Number(expenseRows[0]?.total || 0);

  const [categoryRows] = await pool.query(
    `SELECT t.categoryId, COALESCE(c.name, 'Khác') AS categoryName, COALESCE(SUM(t.amount), 0) AS total
     FROM transactions t
     LEFT JOIN categories c ON c.id = t.categoryId
     WHERE t.userId = ? AND t.type = 'expense'
     GROUP BY t.categoryId, c.name
     ORDER BY total DESC`,
    [userId]
  );

  return {
    income,
    expense,
    balance: income - expense,
    byCategory: categoryRows,
  };
}

module.exports = {
  getSummary,
};
