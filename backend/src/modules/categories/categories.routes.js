const express = require('express');
const { body } = require('express-validator');
const authMiddleware = require('../../middleware/auth.middleware');
const asyncHandler = require('../../utils/asyncHandler');
const controller = require('./categories.controller');

const router = express.Router();

router.get('/', authMiddleware, asyncHandler(controller.list));
router.post(
  '/',
  authMiddleware,
  [
    body('name').isString().trim().notEmpty().withMessage('name is required'),
    body('type').optional().isIn(['income', 'expense']).withMessage('type must be income or expense'),
  ],
  asyncHandler(controller.create)
);
router.put(
  '/:id',
  authMiddleware,
  [
    body('name').isString().trim().notEmpty().withMessage('name is required'),
    body('type').optional().isIn(['income', 'expense']).withMessage('type must be income or expense'),
  ],
  asyncHandler(controller.update)
);
router.delete('/:id', authMiddleware, asyncHandler(controller.remove));

module.exports = router;
