const { validationResult } = require('express-validator');
const categoriesService = require('./categories.service');

function validate(req) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const error = new Error(errors.array().map((e) => e.msg).join(', '));
    error.statusCode = 400;
    throw error;
  }
}

async function list(req, res) {
  const categories = await categoriesService.listCategories();
  res.json({ categories });
}

async function create(req, res) {
  validate(req);
  const category = await categoriesService.createCategory(req.body);
  res.status(201).json({ category });
}

async function update(req, res) {
  validate(req);
  const category = await categoriesService.updateCategory(req.params.id, req.body);
  res.json({ category });
}

async function remove(req, res) {
  await categoriesService.deleteCategory(req.params.id);
  res.status(204).send();
}

module.exports = {
  list,
  create,
  update,
  remove,
};
