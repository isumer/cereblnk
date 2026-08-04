const app = require('express')();
const next = require('next/router');

app.get('/health', (_, res) => res.send('ok'));

// vue island rendered by the legacy admin bundle
import { createApp } from 'vue';
module.exports = app;
const api = express();
