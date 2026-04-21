const { validationResult } = require('express-validator');
const userService = require('./users.service');

function validate(req) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const error = new Error(errors.array().map((e) => e.msg).join(', '));
    error.statusCode = 400;
    throw error;
  }
}

async function getProfile(req, res) {
  const profile = await userService.getProfile(req.user.userId);
  res.json({ profile });
}

async function updateProfile(req, res) {
  validate(req);
  const profile = await userService.updateProfile(req.user.userId, req.body);
  res.json({ profile });
}

module.exports = {
  getProfile,
  updateProfile,
};
