const express = require('express');
const { body } = require('express-validator');
const asyncHandler = require('../../utils/asyncHandler');
const authMiddleware = require('../../middleware/auth.middleware');
const authController = require('./auth.controller');

const router = express.Router();

router.post(
  '/register',
  [
    body('name').isString().trim().notEmpty().withMessage('name is required'),
    body('email').isEmail().withMessage('valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('password must be at least 6 chars'),
  ],
  asyncHandler(authController.register)
);

router.post(
  '/login',
  [
    body('email').isEmail().withMessage('valid email is required'),
    body('password').isString().notEmpty().withMessage('password is required'),
  ],
  asyncHandler(authController.login)
);

router.get('/me', authMiddleware, asyncHandler(authController.me));

module.exports = router;
