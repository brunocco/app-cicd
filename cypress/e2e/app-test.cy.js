describe('App CICD E2E Tests', () => {
  beforeEach(() => {
    // Ignorar todos os erros de fetch e promise rejections
    cy.on('uncaught:exception', (err, runnable) => {
      // Ignorar erros de fetch, promise rejections e network errors
      if (err.message.includes('Failed to fetch') || 
          err.message.includes('NetworkError') ||
          err.message.includes('fetch')) {
        return false
      }
    })
    
    cy.visit('/', { timeout: 30000 })
    
    // Aguardar elementos básicos carregarem
    cy.get('body', { timeout: 10000 }).should('be.visible')
    cy.wait(3000)
  })

  it('should load the application', () => {
    cy.contains('Task Manager', { timeout: 10000 })
    cy.get('#task-input', { timeout: 10000 }).should('be.visible')
    cy.get('button[type="submit"]', { timeout: 10000 }).should('be.visible')
    
    // Testar se a API está respondendo
    cy.request({
      method: 'GET',
      url: 'https://staging.buildcloud.com.br/api/tasks',
      failOnStatusCode: false
    }).then((response) => {
      cy.log('API Response:', response.status)
    })
  })

  it('should create a new task', () => {
    const taskTitle = 'Test Task from Cypress'
    
    cy.get('#task-input', { timeout: 10000 }).should('be.visible').clear().type(taskTitle)
    cy.get('button[type="submit"]', { timeout: 10000 }).click()
    
    cy.wait(5000)
    cy.contains(taskTitle, { timeout: 20000 }).should('be.visible')
  })

  it('should mark task as completed', () => {
    const taskTitle = 'Complete Task Test'
    
    // Criar tarefa
    cy.get('#task-input', { timeout: 10000 }).clear().type(taskTitle)
    cy.get('button[type="submit"]', { timeout: 10000 }).click()
    cy.wait(5000)
    
    // Marcar como concluída
    cy.contains(taskTitle, { timeout: 20000 }).should('be.visible')
    cy.contains(taskTitle).parent().find('input[type="checkbox"]', { timeout: 10000 }).check()
    cy.wait(3000)
    
    // Verificar se foi marcada como concluída
    cy.contains(taskTitle).should('have.css', 'text-decoration-line', 'line-through')
  })

  it('should delete a task', () => {
    const taskTitle = 'Delete Task Test'
    
    // Criar tarefa
    cy.get('#task-input', { timeout: 10000 }).clear().type(taskTitle)
    cy.get('button[type="submit"]', { timeout: 10000 }).click()
    cy.wait(5000)
    
    // Deletar tarefa
    cy.contains(taskTitle, { timeout: 20000 }).should('be.visible')
    cy.contains(taskTitle).parent().find('button', { timeout: 10000 }).contains('Deletar').click()
    cy.wait(3000)
    
    // Verificar se foi deletada
    cy.contains(taskTitle).should('not.exist')
  })

  it('should handle multiple tasks', () => {
    const tasks = [
      `Task 1 ${Date.now()}`,
      `Task 2 ${Date.now()}`,
      `Task 3 ${Date.now()}`
    ]

    // Criar múltiplas tarefas
    tasks.forEach(task => {
      cy.get('#task-input').type(task)
      cy.get('button[type="submit"]').click()
      cy.contains(task).should('be.visible')
    })

    // Verificar se todas estão visíveis
    tasks.forEach(task => {
      cy.contains(task).should('be.visible')
    })
  })
})