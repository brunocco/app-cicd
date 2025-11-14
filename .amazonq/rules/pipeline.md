# Regras de Pipeline - Projeto app-cicd

## Ferramentas
- **GitHub Actions** para CI/CD completo
- **Cypress** para testes E2E automatizados
- **AWS CLI** para deploy de recursos

## Estágios
1. **Detect Changes** → Detecta mudanças em frontend/backend
2. **Deploy Staging** → Deploy automático para staging
3. **E2E Tests** → Testes automatizados com Cypress
4. **Deploy Production** → Deploy manual com aprovação

## Ambientes
- **Staging**: staging.buildcloud.com.br (deploy automático)
- **Production**: www.buildcloud.com.br (aprovação manual)

## Variáveis GitHub Actions

### Secrets (Repository Settings)
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ACCOUNT_ID`

### Variables (Repository Settings)
- `AWS_REGION`: us-east-1
- `ECR_REPOSITORY`: app-cicd-backend
- `ECS_CLUSTER`: app-cicd-cluster
- `ECS_SERVICE_STG`: app-cicd-backend-svc-staging
- `ECS_SERVICE_PROD`: app-cicd-backend-svc-prod
- `ECS_TASK_DEFINITION_STG`: app-cicd-backend-staging
- `ECS_TASK_DEFINITION_PROD`: app-cicd-backend-prod

## Boas práticas
- CloudWatch Logs habilitado.
- Health check configurado no Target Group.
- Rollback automático em caso de falha.
- Deploy canário ou azul/verde se possível.
