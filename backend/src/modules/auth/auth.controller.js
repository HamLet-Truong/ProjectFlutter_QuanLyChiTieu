const { validationResult } = require('express-validator');
const authService = require('./auth.service');

function validate(req) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const error = new Error(errors.array().map((e) => e.msg).join(', '));
    error.statusCode = 400;
    throw error;
  }
}

async function register(req, res) {
  validate(req);
  const result = await authService.register(req.body);
  res.status(201).json(result);
}

async function login(req, res) {
  validate(req);
  const result = await authService.login(req.body);
  res.json(result);
}

async function me(req, res) {
  const user = await authService.getMe(req.user.userId);
  res.json({ user });
}

module.exports = {
  register,
  login,
  me,
};
