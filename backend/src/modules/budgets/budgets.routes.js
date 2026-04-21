const express = require('express');
const { body } = require('express-validator');
const authMiddleware = require('../../middleware/auth.middleware');
const asyncHandler = require('../../utils/asyncHandler');
const controller = require('./budgets.controller');

const router = express.Router();

router.get('/', authMiddleware, asyncHandler(controller.list));
router.post(
  '/',
  authMiddleware,
  [
    body('categoryId').isString().notEmpty().withMessage('categoryId is required'),
    body('limitAmount').isNumeric().withMessage('limitAmount is required'),
    body('startDate').isISO8601().withMessage('startDate must be ISO8601'),
    body('endDate').isISO8601().withMessage('endDate must be ISO8601'),
  ],
  asyncHandler(controller.create)
);
router.put(
  '/:id',
  authMiddleware,
  [
    body('categoryId').isString().notEmpty().withMessage('categoryId is required'),
    body('limitAmount').isNumeric().withMessage('limitAmount is required'),
    body('startDate').isISO8601().withMessage('startDate must be ISO8601'),
    body('endDate').isISO8601().withMessage('endDate must be ISO8601'),
  ],
  asyncHandler(controller.update)
);
router.delete('/:id', authMiddleware, asyncHandler(controller.remove));

module.exports = router;
