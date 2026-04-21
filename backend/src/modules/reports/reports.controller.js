const reportsService = require('./reports.service');

async function summary(req, res) {
  const report = await reportsService.getSummary(req.user.userId);
  res.json({ report });
}

module.exports = {
  summary,
};
