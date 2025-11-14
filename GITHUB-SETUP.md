# 🔧 Configuração GitHub Actions - App CICD

## 📋 Variáveis e Secrets Necessários

### 🔐 Secrets (Repository → Settings → Secrets and variables → Actions → Secrets)

Adicione os seguintes secrets:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY  
AWS_ACCOUNT_ID
```

### 📊 Variables (Repository → Settings → Secrets and variables → Actions → Variables)

Adicione as seguintes variáveis com os valores exatos:

| Nome da Variável | Valor |
|------------------|-------|
| `AWS_REGION` | `us-east-1` |
| `ECR_REPOSITORY` | `app-cicd-backend` |
| `ECS_CLUSTER` | `app-cicd-cluster` |
| `ECS_SERVICE_STG` | `app-cicd-backend-svc-staging` |
| `ECS_SERVICE_PROD` | `app-cicd-backend-svc-prod` |
| `ECS_TASK_DEFINITION_STG` | `app-cicd-backend-staging` |
| `ECS_TASK_DEFINITION_PROD` | `app-cicd-backend-prod` |

## 🌍 Environments (Repository → Settings → Environments)

### 1. Criar Environment "staging"
- Nome: `staging`
- Sem proteções (deploy automático)

### 2. Criar Environment "production"  
- Nome: `production`
- ✅ **Required reviewers**: Adicione seu usuário GitHub
- ✅ **Wait timer**: 0 minutes
- ✅ **Prevent self-review**: Desabilitado (para permitir auto-aprovação)

## 🚀 Como Obter os Valores

### AWS_ACCOUNT_ID
```bash
aws sts get-caller-identity --query Account --output text
```

### AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY
1. AWS Console → IAM → Users → Seu usuário
2. Security credentials → Create access key
3. Use case: CLI
4. Copie Access Key ID e Secret Access Key

## ✅ Checklist de Configuração

- [ ] Secrets configurados no GitHub
- [ ] Variables configuradas no GitHub  
- [ ] Environment "staging" criado
- [ ] Environment "production" criado com aprovação manual
- [ ] Terraform aplicado com sucesso
- [ ] Domínios apontando para Route53
- [ ] Certificados ACM validados

## 🔄 Testando o Pipeline

1. Faça uma alteração no frontend ou backend
2. Commit e push para branch `main`
3. Verifique o pipeline em Actions
4. Aguarde deploy automático no staging
5. Aguarde testes E2E
6. Aprove manualmente o deploy para produção

## 🐛 Troubleshooting

### Pipeline falha com erro de permissão AWS
- Verificar se AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY estão corretos
- Verificar se o usuário IAM tem permissões necessárias

### Environment "production" não aparece
- Certificar que o environment foi criado com nome exato: `production`
- Verificar se Required reviewers foi configurado

### Variáveis não são reconhecidas
- Verificar se os nomes das variáveis estão exatos (case-sensitive)
- Aguardar alguns minutos após criar as variáveis