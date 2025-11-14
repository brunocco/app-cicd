describe('App CICD E2E Tests', () => {
  beforeEach(() => {
    cy.visit('/')
  })

  it('should load the application', () => {
    cy.contains('Task Manager')
    cy.get('#task-input').should('be.visible')
    cy.get('button[type="submit"]').should('be.visible')
  })

  it('should create a new task', () => {
    const taskTitle = `Test Task ${Date.now()}`
    
    cy.get('#task-input').type(taskTitle)
    cy.get('button[type="submit"]').click()
    
    cy.contains(taskTitle).should('be.visible')
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