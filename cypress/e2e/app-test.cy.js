describe('App CICD E2E Tests', () => {
  beforeEach(() => {
    cy.on('uncaught:exception', () => false)
    cy.visit('/', { timeout: 30000 })
    cy.get('body', { timeout: 10000 }).should('be.visible')
    cy.wait(2000)
  })

  it('should load the application', () => {
    cy.contains('Task Manager', { timeout: 10000 })
    cy.get('#task-input', { timeout: 10000 }).should('be.visible')
    cy.get('button[type="submit"]', { timeout: 10000 }).should('be.visible')
  })

  it('should create a new task', () => {
    const taskTitle = 'Test Task from Cypress'
    cy.get('#task-input', { timeout: 10000 }).clear().type(taskTitle)
    cy.get('button[type="submit"]').click()
    cy.wait(3000)
    cy.get('body').should('contain', taskTitle)
  })
})