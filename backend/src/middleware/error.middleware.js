function notFoundMiddleware(req, res) {
  res.status(404).json({ message: 'Route not found' });
}

function errorMiddleware(err, req, res, next) {
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  if (process.env.NODE_ENV !== 'production') {
    // eslint-disable-next-line no-console
    console.error(err);
  }

  res.status(statusCode).json({ message });
}

module.exports = {
  notFoundMiddleware,
  errorMiddleware,
};
