#!/usr/bin/env node

console.log('🚀 Starting from root wrapper...');
console.log('📁 Current directory:', process.cwd());
console.log('🔍 Listing files:', require('fs').readdirSync('.'));

const path = require('path');
const serverPath = path.join(__dirname, 'server');
console.log('📂 Server path:', serverPath);
console.log('📋 Server files:', require('fs').readdirSync(serverPath));

process.chdir(serverPath);
console.log('📂 Changed to server directory:', process.cwd());

// Now start the server
require('./server.js');