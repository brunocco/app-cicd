const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    baseUrl: 'https://d128yqhncqex8w.cloudfront.net',
    supportFile: false,
    video: false,
    screenshot: false,
    defaultCommandTimeout: 15000,
    requestTimeout: 15000,
    responseTimeout: 15000
  }
})