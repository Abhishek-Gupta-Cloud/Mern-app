const mongoose = require("mongoose");
const logger = require("../utils/logger");

const connectDB = async () => {
  const uri = process.env.MONGO_URI;
  if (!uri) throw new Error("MONGO_URI is not defined in environment");

  try {
    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });
    logger.info(`MongoDB connected: ${conn.connection.host}`);
  } catch (err) {
    logger.error("MongoDB connection failed:", err.message);
    process.exit(1);
  }

  mongoose.connection.on("disconnected", () =>
    logger.warn("MongoDB disconnected – retrying...")
  );
  mongoose.connection.on("error", (err) =>
    logger.error("MongoDB error:", err.message)
  );
};

module.exports = connectDB;
