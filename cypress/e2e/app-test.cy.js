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
  })

  it('should create a new task', () => {
    const taskTitle = `Test Task ${Date.now()}`
    
    cy.get('#task-input', { timeout: 10000 }).should('be.visible').type(taskTitle)
    cy.get('button[type="submit"]', { timeout: 10000 }).click()
    
    cy.wait(2000)
    cy.contains(taskTitle, { timeout: 15000 }).should('be.visible')
  })

  it('should mark task as completed', () => {
    const taskTitle = `Complete Task ${Date.now()}`
    
    // Criar tarefa
    cy.get('#task-input').type(taskTitle)
    cy.get('button[type="submit"]').click()
    
    // Marcar como concluída
    cy.contains(taskTitle).parent().find('input[type="checkbox"]').check()
    
    // Verificar se foi marcada como concluída
    cy.contains(taskTitle).should('have.css', 'text-decoration-line', 'line-through')
  })

  it('should delete a task', () => {
    const taskTitle = `Delete Task ${Date.now()}`
    
    // Criar tarefa
    cy.get('#task-input').type(taskTitle)
    cy.get('button[type="submit"]').click()
    
    // Deletar tarefa
    cy.contains(taskTitle).parent().find('button').contains('Deletar').click()
    
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