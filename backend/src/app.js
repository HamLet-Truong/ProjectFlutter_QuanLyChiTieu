const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const authRoutes = require('./modules/auth/auth.routes');
const userRoutes = require('./modules/users/users.routes');
const categoryRoutes = require('./modules/categories/categories.routes');
const transactionRoutes = require('./modules/transactions/transactions.routes');
const budgetRoutes = require('./modules/budgets/budgets.routes');
const reportRoutes = require('./modules/reports/reports.routes');
const { notFoundMiddleware, errorMiddleware } = require('./middleware/error.middleware');

const app = express();

app.use(cors());
app.use(helmet());
app.use(express.json());
app.use(morgan('dev'));

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/budgets', budgetRoutes);
app.use('/api/reports', reportRoutes);

app.use(notFoundMiddleware);
app.use(errorMiddleware);

module.exports = app;
