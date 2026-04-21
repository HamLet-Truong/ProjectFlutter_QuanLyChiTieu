const express = require('express');
const { body } = require('express-validator');
const asyncHandler = require('../../utils/asyncHandler');
const authMiddleware = require('../../middleware/auth.middleware');
const usersController = require('./users.controller');

const router = express.Router();

router.get('/profile', authMiddleware, asyncHandler(usersController.getProfile));
router.put(
  '/profile',
  authMiddleware,
  [
    body('name').isString().trim().notEmpty().withMessage('name is required'),
    body('email').isEmail().withMessage('valid email is required'),
  ],
  asyncHandler(usersController.updateProfile)
);

module.exports = router;
