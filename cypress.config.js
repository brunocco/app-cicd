const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    baseUrl: 'https://staging.buildcloud.com.br',
    supportFile: false,
    video: false,
    screenshot: false,
    defaultCommandTimeout: 15000,
    requestTimeout: 15000,
    responseTimeout: 15000
  }
})