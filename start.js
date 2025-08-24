#!/usr/bin/env node

console.log('🚀 Starting LuWay app from wrapper...');
console.log('📁 Current directory:', process.cwd());
console.log('🎯 About to run server/server.js');

// Load and run the server
require('./server/server.js');