const express = require('express');
const authMiddleware = require('../../middleware/auth.middleware');
const asyncHandler = require('../../utils/asyncHandler');
const controller = require('./reports.controller');

const router = express.Router();

router.get('/summary', authMiddleware, asyncHandler(controller.summary));

module.exports = router;
