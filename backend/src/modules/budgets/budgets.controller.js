const { validationResult } = require('express-validator');
const service = require('./budgets.service');

function validate(req) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const error = new Error(errors.array().map((e) => e.msg).join(', '));
    error.statusCode = 400;
    throw error;
  }
}

async function list(req, res) {
  const budgets = await service.listBudgets();
  res.json({ budgets });
}

async function create(req, res) {
  validate(req);
  const budget = await service.createBudget(req.body);
  res.status(201).json({ budget });
}

async function update(req, res) {
  validate(req);
  const budget = await service.updateBudget(req.params.id, req.body);
  res.json({ budget });
}

async function remove(req, res) {
  await service.deleteBudget(req.params.id);
  res.status(204).send();
}

module.exports = {
  list,
  create,
  update,
  remove,
};
