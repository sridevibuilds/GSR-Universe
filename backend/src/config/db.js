const { Pool } = require("pg");
require("dotenv").config();

const host = process.env.DB_HOST || "localhost";
const isLocal = host === "localhost" || host === "127.0.0.1";
const useSSL = process.env.DB_SSL === "true" || (!isLocal && process.env.NODE_ENV === "production");

const poolConfig = {
  host: host,
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || "gsr_universe",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres",
};

if (useSSL) {
  poolConfig.ssl = {
    rejectUnauthorized: false,
  };
}

const pool = new Pool(poolConfig);

module.exports = pool;