require('dotenv').config();

const app = require('./app');
const { verifyConnection, ensureDatabaseArtifacts } = require('./config/db');

const port = Number(process.env.PORT || 3000);

async function startServer() {
  try {
    await verifyConnection();
    await ensureDatabaseArtifacts();

    app.listen(port, () => {
      // eslint-disable-next-line no-console
      console.log(`Backend API running on port ${port}`);
    });
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to start backend:', error.message);
    process.exit(1);
  }
}

startServer();
