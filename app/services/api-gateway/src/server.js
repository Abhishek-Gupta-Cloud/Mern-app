require('dotenv').config();
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const morgan = require('morgan');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(morgan('dev'));

const AUTH_TARGET = process.env.AUTH_URL || 'http://localhost:5001';
const TASKS_TARGET = process.env.TASKS_URL || 'http://localhost:5002';

app.use('/api/auth', createProxyMiddleware({ target: AUTH_TARGET, changeOrigin: true, pathRewrite: { '^/api/auth': '/api/auth' } }));
app.use('/api/tasks', createProxyMiddleware({ target: TASKS_TARGET, changeOrigin: true, pathRewrite: { '^/api/tasks': '/api/tasks' } }));

app.get('/api/health', (_req, res) => res.json({ status: 'ok', service: 'gateway' }));

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`API Gateway listening on ${PORT}`));
