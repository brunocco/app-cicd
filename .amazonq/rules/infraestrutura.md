# Regras de Infraestrutura - Projeto app-cicd

## Arquitetura Atual

### Frontend (Estático)
- **Amazon S3**: 2 buckets para hospedagem estática (staging/prod)
- **CloudFront**: CDN global com certificados SSL/TLS existentes
- **ACM**: Certificados wildcard pré-existentes para buildcloud.com.br
- **Route53**: DNS com registros A/CNAME para domínios personalizados
- **Domínios**: staging.buildcloud.com.br e www.buildcloud.com.br

### Backend (Containerizado)
- **Amazon ECS Fargate**: Orquestração serverless (2 ambientes independentes)
- **Application Load Balancer**: 2 ALBs com path-based routing (/api/*)
- **Amazon ECR**: 1 repositório para imagens Docker do backend
- **Capacidade**: 1 task por ambiente (256 CPU / 512 MB RAM)

### Banco de Dados
- **Amazon RDS PostgreSQL 17**: 2 instâncias independentes (t3.micro, 20GB gp2)
- **Multi-AZ**: Configurado para alta disponibilidade
- **SSL**: Conexão obrigatória com rejectUnauthorized: false

### Rede (Compartilhada)
- **VPC**: 10.0.0.0/16 com DNS habilitado
- **Subnets Públicas**: 10.0.1.0/24 (us-east-1a) e 10.0.2.0/24 (us-east-1b)
- **Subnets Privadas**: 10.0.3.0/24 (us-east-1a) e 10.0.4.0/24 (us-east-1b)
- **2 NAT Gateways**: 1 por AZ para alta disponibilidade
- **Internet Gateway**: Para conectividade externa

### CI/CD
- **GitHub Actions**: Pipeline completo com detecção de mudanças
- **Cypress**: Testes E2E automatizados (2 testes)
- **Aprovação Manual**: Deploy para produção requer aprovação

## Recursos Implementados

### S3 + CloudFront
- **2 Buckets S3**: `app-cicd-frontend-staging` e `app-cicd-frontend-prod`
- **Website Configuration**: index.html como documento padrão
- **Origin Access Control**: Acesso seguro via CloudFront
- **2 Distribuições CloudFront**: Uma por ambiente
- **Cache Behaviors**:
  - Default: S3 (arquivos estáticos)
  - `/api/*`: ALB (API backend)
- **SSL/TLS**: Certificados ACM existentes

### Application Load Balancer
- **2 ALBs**: `app-cicd-alb-staging` e `app-cicd-alb-prod`
- **Target Groups**: `app-cicd-backend-tg-staging` e `app-cicd-backend-tg-prod`
- **Health Check**: `/tasks` (porta 3000)
- **Listener Rules**:
  - Priority 100: `/api/*` → Backend Target Group
  - Priority Default: Outras requisições

### ECS Fargate
- **Cluster**: `app-cicd-cluster` (compartilhado)
- **Services**: 
  - `app-cicd-backend-svc-staging`
  - `app-cicd-backend-svc-prod`
- **Task Definitions**:
  - `app-cicd-backend-staging`
  - `app-cicd-backend-prod`
- **Network Mode**: awsvpc
- **Subnets**: Privadas com assign_public_ip = false

### Security Groups
- **ALB SG**: Ingress 80/443 de 0.0.0.0/0, egress all
- **ECS Backend SG**: Ingress 3000 apenas do ALB, egress all
- **RDS SG**: Ingress 5432 apenas do ECS Backend, egress all
- **Princípio**: Menor privilégio aplicado

### RDS PostgreSQL
- **2 Instâncias**: `app-cicd-db-staging` e `app-cicd-db-prod`
- **Engine**: PostgreSQL 17.6
- **Instance Class**: db.t3.micro
- **Storage**: 20GB gp2
- **DB Subnet Group**: `app-cicd-db-subnet-group`
- **Publicly Accessible**: false
- **SSL**: Obrigatório

### Route53
- **Hosted Zone**: buildcloud.com.br (pré-existente)
- **Registros A**: Alias para distribuições CloudFront
- **Domínios**:
  - staging.buildcloud.com.br → CloudFront Staging
  - www.buildcloud.com.br → CloudFront Production

### Observabilidade
- **CloudWatch Log Groups**:
  - `/ecs/app-cicd/backend/staging`
  - `/ecs/app-cicd/backend/prod`
- **Retenção**: 7 dias
- **Log Driver**: awslogs
- **Health Checks**: Configurados em ALB e ECS

### IAM
- **Execution Role**: `app-cicd-execution-role`
- **Policy**: AmazonECSTaskExecutionRolePolicy
- **Trust Relationship**: ecs-tasks.amazonaws.com

## Provisionamento Terraform

Infraestrutura gerenciada via **Terraform** em arquivo único `infra/main.tf`:

1. **Provider AWS** (us-east-1)
2. **Data Sources** (Account ID, Route53 Zone)
3. **VPC e Subnets** (4 subnets em 2 AZs)
4. **Internet Gateway + NAT Gateways** (2 NATs)
5. **Route Tables** (1 pública + 2 privadas)
6. **S3 Buckets + Website Configuration** (2 buckets)
7. **CloudFront Origin Access Control** (2 OACs)
8. **CloudFront Distributions** (2 distribuições)
9. **S3 Bucket Policies** (acesso via CloudFront)
10. **Route53 Records** (DNS para domínios)
11. **Security Groups** (3 grupos)
12. **Application Load Balancers** (2 ALBs)
13. **Target Groups + Listeners** (2 TGs)
14. **ECS Cluster** (compartilhado)
15. **RDS Subnet Group + Instances** (2 instâncias)
16. **IAM Role + Policy Attachment**
17. **CloudWatch Log Groups** (2 grupos)
18. **ECS Task Definitions** (2 definições)
19. **ECS Services** (2 serviços)
20. **Outputs** (URLs, endpoints, ARNs)

## Pipeline CI/CD

### Trigger
- **Detecção Automática**: Mudanças em `frontend/` ou `backend/`
- **Path Filter**: Executa jobs apenas se houver mudanças relevantes

### Fluxo
1. **Detect Changes**: Identifica alterações em frontend/backend
2. **Deploy Staging**: 
   - Frontend: S3 sync + CloudFront invalidation
   - Backend: Docker build + ECR push + ECS deploy
3. **E2E Tests**: Cypress com 2 testes automatizados
4. **Deploy Production**: Aprovação manual + deploy idêntico

### Ambientes GitHub Actions
- **staging**: Deploy automático
- **production**: Requer aprovação manual

## Padrão de Nomes

Seguir rigorosamente o arquivo `naming.md`:
- **Prefixo**: `app-cicd`
- **Separador**: hífen (`-`)
- **Formato**: `app-cicd-<recurso>-<ambiente/especificador>`
- **Exemplos**:
  - `app-cicd-backend-svc-staging`
  - `app-cicd-frontend-prod`
  - `app-cicd-alb-staging`

## Boas Práticas Implementadas

### Segurança
- ✅ Security Groups com princípio de menor privilégio
- ✅ RDS em subnets privadas sem acesso público
- ✅ Conexão SSL obrigatória no PostgreSQL
- ✅ ECS tasks em subnets privadas
- ✅ CloudFront com Origin Access Control
- ✅ S3 buckets com acesso restrito
- ⚠️ Credenciais em variáveis de ambiente (migrar para Secrets Manager)

### Rede
- ✅ Multi-AZ para alta disponibilidade
- ✅ 2 NAT Gateways (1 por AZ)
- ✅ Subnets públicas apenas para ALB
- ✅ Subnets privadas para ECS e RDS
- ✅ DNS habilitado na VPC

### Observabilidade
- ✅ CloudWatch Logs habilitado
- ✅ Health checks configurados (ALB + ECS)
- ✅ Log retention configurado (7 dias)
- ⚠️ Container Insights desabilitado (considerar habilitar)
- ⚠️ Sem alarmes configurados (adicionar)

### Performance
- ✅ CloudFront CDN global
- ✅ Cache behaviors otimizados
- ✅ Fargate serverless (sem overhead de EC2)
- ✅ RDS em subnets privadas

### Custos
- ✅ Fargate (sem EC2 para gerenciar)
- ✅ RDS t3.micro (tier gratuito elegível)
- ✅ S3 Standard (baixo custo para arquivos estáticos)
- ⚠️ 2 NAT Gateways (~$64/mês) - considerar 1 NAT para dev
- ⚠️ Sem Auto Scaling (fixo em 1 task por ambiente)

## Melhorias Recomendadas

### 1. Segurança
- Migrar credenciais para AWS Secrets Manager
- Implementar WAF no CloudFront
- Habilitar encryption at rest no RDS
- Adicionar HTTPS redirect no ALB
- Implementar AWS Config para compliance

### 2. Observabilidade
- Habilitar Container Insights no ECS
- Criar CloudWatch Alarms (CPU, memória, erros)
- Configurar SNS para notificações
- Adicionar X-Ray para distributed tracing
- Implementar dashboards personalizados

### 3. Escalabilidade
- Configurar Auto Scaling (1-3 tasks)
- Adicionar Application Auto Scaling policies
- Considerar Aurora Serverless v2 para RDS
- Implementar ElastiCache Redis para cache
- Adicionar read replicas no RDS

### 4. Performance
- Configurar CloudFront edge locations
- Implementar S3 Transfer Acceleration
- Otimizar cache TTL no CloudFront
- Adicionar compressão gzip
- Implementar HTTP/2 e HTTP/3

### 5. Custos
- Usar 1 NAT Gateway em ambiente dev
- Implementar lifecycle policies no ECR
- Considerar Savings Plans para Fargate
- Implementar S3 Intelligent Tiering
- Configurar RDS Reserved Instances

### 6. CI/CD
- Adicionar testes unitários
- Implementar análise de código (SonarQube)
- Deploy canário ou blue/green
- Rollback automático baseado em métricas
- Adicionar smoke tests pós-deploy

### 7. Backup e Disaster Recovery
- Configurar backup automático do RDS
- Implementar cross-region replication
- Criar runbooks para disaster recovery
- Configurar point-in-time recovery
- Implementar backup do S3 cross-region

## Estimativa de Custos (Mensal)

| Serviço | Staging | Production | Total |
|---------|---------|------------|-------|
| ECS Fargate | $15 | $15 | $30 |
| RDS t3.micro | $15 | $15 | $30 |
| ALB | $18 | $18 | $36 |
| NAT Gateway | $32 | $32 | $64 |
| CloudFront | $1 | $5 | $6 |
| S3 | $1 | $1 | $2 |
| Route53 | - | $0.50 | $0.50 |
| ECR | $1 | $1 | $2 |
| **Total** | - | - | **~$170** |

> **Nota**: Custos podem variar baseado no uso real e região AWS.