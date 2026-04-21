const { validationResult } = require('express-validator');
const service = require('./transactions.service');

function validate(req) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const error = new Error(errors.array().map((e) => e.msg).join(', '));
    error.statusCode = 400;
    throw error;
  }
}

async function list(req, res) {
  const transactions = await service.listTransactions(req.user.userId);
  res.json({ transactions });
}

async function create(req, res) {
  validate(req);
  const transaction = await service.createTransaction(req.user.userId, req.body);
  res.status(201).json({ transaction });
}

async function update(req, res) {
  validate(req);
  const transaction = await service.updateTransaction(req.user.userId, req.params.id, req.body);
  res.json({ transaction });
}

async function remove(req, res) {
  await service.deleteTransaction(req.user.userId, req.params.id);
  res.status(204).send();
}

module.exports = {
  list,
  create,
  update,
  remove,
};
