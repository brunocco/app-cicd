# Regras de Pipeline - Projeto app-task

## Ferramentas
- CodePipeline + CodeBuild + ECS Deploy.
- Alternativamente, pode ser usado **GitHub Actions** para build e deploy.

## Estágios
1. **Source** → GitHub Repository.
2. **Build** → CodeBuild (ou Actions) gera e envia imagem ao ECR.
3. **Deploy** → ECS atualiza os serviços (frontend / backend).

## Variáveis de ambiente
- Configurar no pipeline:
  - `ECR_REPO`
  - `ECS_CLUSTER`
  - `SERVICE_NAME`
  - `AWS_REGION`
  - `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_NAME` (no backend)

## Boas práticas
- CloudWatch Logs habilitado.
- Health check configurado no Target Group.
- Rollback automático em caso de falha.
- Deploy canário ou azul/verde se possível.
