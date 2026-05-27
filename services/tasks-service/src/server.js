require('dotenv').config();
require('express-async-errors');

const app = require('./app');
const connectDB = require('./config/db');
const logger = require('./utils/logger');

const PORT = process.env.PORT || 5002;

(async () => {
  await connectDB();
  app.listen(PORT, () => {
    logger.info(`Tasks service running on port ${PORT} [${process.env.NODE_ENV}]`);
  });
})();
