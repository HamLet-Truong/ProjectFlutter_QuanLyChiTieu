const { randomUUID } = require('crypto');
const { pool } = require('../../config/db');

async function listCategories() {
  const [rows] = await pool.query(
    'SELECT id, name, iconPath, colorHex, type FROM categories ORDER BY type ASC, name ASC'
  );
  return rows;
}

async function createCategory(payload) {
  const id = randomUUID();
  const category = {
    id,
    name: payload.name,
    iconPath: payload.iconPath || 'category',
    colorHex: payload.colorHex || '#6C63FF',
    type: payload.type || 'expense',
  };

  await pool.query(
    'INSERT INTO categories (id, name, iconPath, colorHex, type) VALUES (?, ?, ?, ?, ?)',
    [category.id, category.name, category.iconPath, category.colorHex, category.type]
  );

  return category;
}

async function updateCategory(id, payload) {
  await pool.query(
    'UPDATE categories SET name = ?, iconPath = ?, colorHex = ?, type = ? WHERE id = ?',
    [
      payload.name,
      payload.iconPath || 'category',
      payload.colorHex || '#6C63FF',
      payload.type || 'expense',
      id,
    ]
  );

  const [rows] = await pool.query(
    'SELECT id, name, iconPath, colorHex, type FROM categories WHERE id = ? LIMIT 1',
    [id]
  );

  if (rows.length === 0) {
    const error = new Error('Category not found');
    error.statusCode = 404;
    throw error;
  }

  return rows[0];
}

async function deleteCategory(id) {
  const [result] = await pool.query('DELETE FROM categories WHERE id = ?', [id]);
  if (result.affectedRows === 0) {
    const error = new Error('Category not found');
    error.statusCode = 404;
    throw error;
  }
}

module.exports = {
  listCategories,
  createCategory,
  updateCategory,
  deleteCategory,
};
