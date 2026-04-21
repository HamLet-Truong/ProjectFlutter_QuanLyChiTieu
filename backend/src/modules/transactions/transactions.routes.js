const express = require('express');
const { body } = require('express-validator');
const authMiddleware = require('../../middleware/auth.middleware');
const asyncHandler = require('../../utils/asyncHandler');
const controller = require('./transactions.controller');

const router = express.Router();

router.get('/', authMiddleware, asyncHandler(controller.list));
router.post(
  '/',
  authMiddleware,
  [
    body('amount').isNumeric().withMessage('amount is required'),
    body('type').isIn(['income', 'expense']).withMessage('type must be income or expense'),
    body('categoryId').isString().notEmpty().withMessage('categoryId is required'),
    body('date').optional().isISO8601().withMessage('date must be ISO8601'),
  ],
  asyncHandler(controller.create)
);
router.put(
  '/:id',
  authMiddleware,
  [
    body('amount').isNumeric().withMessage('amount is required'),
    body('type').isIn(['income', 'expense']).withMessage('type must be income or expense'),
    body('categoryId').isString().notEmpty().withMessage('categoryId is required'),
    body('date').isISO8601().withMessage('date must be ISO8601'),
  ],
  asyncHandler(controller.update)
);
router.delete('/:id', authMiddleware, asyncHandler(controller.remove));

module.exports = router;
