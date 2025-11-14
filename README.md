# 🚀 App-CICD - Aplicação Full-Stack Multi-Ambiente na AWS

## 📋 Introdução

**App-CICD** é uma aplicação completa de gerenciamento de tarefas (To-Do List) desenvolvida com arquitetura moderna de microsserviços, demonstrando implementação de CI/CD com múltiplos ambientes na AWS.

O projeto implementa uma infraestrutura cloud escalável, segura e de alta disponibilidade com pipeline automatizado de deploy, testes E2E e aprovação manual para produção.

### 🎯 Objetivos do Projeto

- Demonstrar CI/CD completo com GitHub Actions
- Implementar múltiplos ambientes (staging/production)
- Utilizar S3 + CloudFront para frontend estático
- Aplicar testes automatizados E2E com Cypress
- Implementar aprovação manual para produção
- Usar certificados SSL/TLS com ACM
- Demonstrar infraestrutura como código com Terraform

---

## 🏗️ Arquitetura da Solução

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions CI/CD                    │
├─────────────────────────────────────────────────────────────┤
│  1. Detect Changes → 2. Deploy Staging → 3. E2E Tests      │
│                    → 4. Manual Approval → 5. Deploy Prod   │
└─────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                            │
├─────────────────────────────────────────────────────────────┤
│  Route53 DNS                                               │
│  ├── staging.buildcloud.com.br → CloudFront (Staging)      │
│  └── www.buildcloud.com.br → CloudFront (Production)       │
│                                ↓                            │
│  CloudFront + ACM (SSL)                                    │
│  ├── S3 Bucket (Frontend Staging)                         │
│  └── S3 Bucket (Frontend Production)                      │
│                                ↓                            │
│  Application Load Balancer                                 │
│  ├── ALB Staging → ECS Backend Staging                     │
│  └── ALB Production → ECS Backend Production               │
│                                ↓                            │
│  ECS Fargate (Backend)                                     │
│  ├── Task Staging → RDS PostgreSQL Staging                │
│  └── Task Production → RDS PostgreSQL Production          │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Estrutura do Projeto

```
app-cicd/
├── .github/workflows/           # GitHub Actions CI/CD
│   └── deploy.yml              # Pipeline principal
├── .amazonq/                   # Configurações Amazon Q
│   └── rules/                  # Regras de infraestrutura
├── backend/                    # API REST Node.js
│   ├── app.js                 # Servidor Express
│   ├── Dockerfile             # Container backend
│   └── package.json
├── frontend/                   # Interface web estática
│   ├── index.html             # Interface HTML
│   └── app.js                 # Lógica JavaScript
├── infra/                     # Infraestrutura Terraform
│   └── main.tf                # Configuração completa
├── cypress/                   # Testes E2E
│   └── e2e/
│       └── app-test.cy.js     # Testes automatizados
├── cypress.config.js          # Configuração Cypress
└── README.md                  # Documentação
```

---

## ☁️ Recursos AWS Utilizados

### Frontend (Estático)
- **Amazon S3**: Hospedagem de arquivos estáticos (2 buckets)
- **CloudFront**: CDN global com cache e HTTPS
- **ACM**: Certificados SSL/TLS gratuitos
- **Route53**: DNS para domínios personalizados

### Backend (Containerizado)
- **Amazon ECS Fargate**: Orquestração serverless (2 ambientes)
- **Application Load Balancer**: Balanceamento HTTP/HTTPS (2 ALBs)
- **Amazon ECR**: Registro privado de containers

### Banco de Dados
- **Amazon RDS PostgreSQL**: Banco gerenciado (2 instâncias)
- **Multi-AZ**: Alta disponibilidade

### Rede e Segurança
- **VPC**: Rede virtual isolada compartilhada
- **Subnets**: Públicas e privadas em múltiplas AZs
- **Security Groups**: Controle granular de tráfego
- **NAT Gateways**: Conectividade de saída segura

### Observabilidade
- **CloudWatch Logs**: Logs centralizados por ambiente
- **Health Checks**: Monitoramento de saúde dos serviços

---

## 🔄 Pipeline CI/CD

### Fluxo Automatizado

1. **Detecção de Mudanças**
   - Monitora alterações em `frontend/` e `backend/`
   - Executa jobs apenas se houver mudanças

2. **Deploy Staging (Automático)**
   - Frontend: Sync para S3 + invalidação CloudFront
   - Backend: Build Docker + push ECR + deploy ECS

3. **Testes E2E (Cypress)**
   - Testa funcionalidades críticas no staging
   - Valida criação, edição e exclusão de tarefas

4. **Deploy Produção (Manual)**
   - Requer aprovação manual no GitHub
   - Deploy idêntico ao staging

### Ambientes

| Ambiente | URL | Deploy | Banco |
|----------|-----|--------|-------|
| **Staging** | https://staging.buildcloud.com.br | Automático | RDS Staging |
| **Production** | https://www.buildcloud.com.br | Manual | RDS Production |

---

## 🛠️ Configuração e Deploy

### 1️⃣ Pré-requisitos

- Conta AWS com permissões administrativas
- Domínio registrado (buildcloud.com.br)
- GitHub repository
- AWS CLI configurado
- Terraform instalado

### 2️⃣ Configurar Domínios no Route53

```bash
# Criar hosted zone (se não existir)
aws route53 create-hosted-zone --name buildcloud.com.br --caller-reference $(date +%s)

# Anotar os name servers para configurar no registrador do domínio
aws route53 get-hosted-zone --id /hostedzone/YOUR_ZONE_ID
```

### 3️⃣ Provisionar Infraestrutura

```bash
cd infra

# Atualizar Account ID no Terraform
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
sed -i "s/ACCOUNT_ID/$ACCOUNT_ID/g" main.tf

# Aplicar infraestrutura
terraform init
terraform plan
terraform apply -auto-approve
```

**Tempo estimado**: 15-20 minutos (certificados ACM podem demorar)

### 4️⃣ Configurar GitHub Actions

#### Secrets (Repository → Settings → Secrets)
```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_ACCOUNT_ID=123456789012
```

#### Variables (Repository → Settings → Variables)
```
AWS_REGION=us-east-1
ECR_REPOSITORY=app-cicd-backend
ECS_CLUSTER=app-cicd-cluster
ECS_SERVICE_STG=app-cicd-backend-svc-staging
ECS_SERVICE_PROD=app-cicd-backend-svc-prod
ECS_TASK_DEFINITION_STG=app-cicd-backend-staging
ECS_TASK_DEFINITION_PROD=app-cicd-backend-prod
```

### 5️⃣ Configurar Environments no GitHub

1. **Repository → Settings → Environments**
2. Criar environment `staging` (sem proteção)
3. Criar environment `production` com:
   - ✅ Required reviewers (você)
   - ✅ Wait timer: 0 minutes

### 6️⃣ Primeiro Deploy

```bash
# Fazer push para main branch
git add .
git commit -m "Initial deployment"
git push origin main
```

O pipeline será executado automaticamente.

---

## 🧪 Testes E2E

Os testes Cypress validam:

- ✅ Carregamento da aplicação
- ✅ Criação de nova tarefa
- ✅ Marcação como concluída
- ✅ Exclusão de tarefa
- ✅ Múltiplas tarefas

### Executar Localmente

```bash
npm install cypress --save-dev
npx cypress open
```

---

## 📊 Monitoramento

### CloudWatch Logs
- `/ecs/app-cicd/backend/staging`
- `/ecs/app-cicd/backend/prod`

### Health Checks
- **Backend**: `GET /tasks` (porta 3000)
- **Frontend**: Servido pelo CloudFront

### Comandos Úteis

```bash
# Ver logs do backend staging
aws logs tail /ecs/app-cicd/backend/staging --follow

# Status dos serviços ECS
aws ecs describe-services --cluster app-cicd-cluster --services app-cicd-backend-svc-staging app-cicd-backend-svc-prod

# Health check dos target groups
aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups --names app-cicd-backend-tg-staging --query 'TargetGroups[0].TargetGroupArn' --output text)
```

---

## 💰 Estimativa de Custos (Mensal)

| Serviço | Staging | Production | Total |
|---------|---------|------------|-------|
| **ECS Fargate** | $15 | $15 | $30 |
| **RDS t3.micro** | $15 | $15 | $30 |
| **ALB** | $18 | $18 | $36 |
| **NAT Gateway** | $32 | $32 | $64 |
| **CloudFront** | $1 | $5 | $6 |
| **S3** | $1 | $1 | $2 |
| **Route53** | - | $0.50 | $0.50 |
| **ACM** | Gratuito | Gratuito | $0 |
| **Total** | - | - | **~$168** |

> **Otimização**: Para desenvolvimento, considere usar 1 NAT Gateway (-$32/mês)

---

## 🔧 Troubleshooting

### Pipeline Falha no Deploy
```bash
# Verificar status do ECS service
aws ecs describe-services --cluster app-cicd-cluster --service app-cicd-backend-svc-staging

# Verificar logs da task
aws logs tail /ecs/app-cicd/backend/staging --follow
```

### Certificado ACM Pendente
- Verificar se os registros DNS foram criados no Route53
- Aguardar até 30 minutos para validação

### Testes Cypress Falhando
- Verificar se o staging está acessível
- Aguardar 2-3 minutos após deploy para estabilização

### Frontend não Carrega
```bash
# Verificar invalidação do CloudFront
aws cloudfront list-invalidations --distribution-id YOUR_DISTRIBUTION_ID

# Forçar nova invalidação
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

---

## 🚀 Melhorias Futuras

- [ ] **Segurança**: Migrar credenciais para AWS Secrets Manager
- [ ] **Observabilidade**: Implementar X-Ray tracing
- [ ] **Performance**: Adicionar ElastiCache Redis
- [ ] **Escalabilidade**: Auto Scaling para ECS
- [ ] **Segurança**: WAF no CloudFront
- [ ] **Backup**: Snapshots automáticos do RDS
- [ ] **Notificações**: SNS para alertas
- [ ] **Blue/Green**: Deploy sem downtime

---

## 🧹 Limpeza de Recursos

```bash
# Destruir infraestrutura
cd infra
terraform destroy -auto-approve

# Limpar buckets S3 manualmente (se necessário)
aws s3 rm s3://app-cicd-frontend-staging --recursive
aws s3 rm s3://app-cicd-frontend-prod --recursive
```

---

## 📚 Tecnologias Utilizadas

- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **Backend**: Node.js, Express.js, PostgreSQL
- **Infraestrutura**: AWS (ECS, S3, CloudFront, RDS, ALB)
- **IaC**: Terraform
- **CI/CD**: GitHub Actions
- **Testes**: Cypress E2E
- **Monitoramento**: CloudWatch
- **SSL/TLS**: AWS Certificate Manager

---

## 👤 Autor

**Bruno Cesar**
- 📧 Email: bruno_cco@hotmail.com
- 💼 LinkedIn: [bruno-cesar-704265223](https://www.linkedin.com/in/bruno-cesar-704265223/)
- 🐙 GitHub: [brunocco](https://github.com/brunocco)

---

## 📄 Licença

Este projeto está sob a licença MIT.

---

⭐ **Se este projeto foi útil, considere dar uma estrela no GitHub!**