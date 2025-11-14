# Regras de Infraestrutura - Projeto app-cicd

## Arquitetura
- **Frontend**: S3 + CloudFront + ACM (2 ambientes: staging/prod)
- **Backend**: ECS com Fargate (2 ambientes independentes)
- **Banco de dados**: Amazon RDS PostgreSQL 17 (t3.micro, 20GB gp2) - 2 instâncias
- **Container Registry**: Amazon ECR (1 repositório backend)
- **Rede**: VPC multi-AZ com subnets públicas e privadas (compartilhada)
- **Observabilidade**: CloudWatch Logs (retenção 7 dias)
- **Capacidade**: 1 task por serviço (256 CPU / 512 MB RAM)
- **CI/CD**: GitHub Actions com testes automatizados
- **Domínios**: staging.buildcloud.com.br e www.buildcloud.com.br

## Recursos obrigatórios

### Rede
- **VPC**: 10.0.0.0/16 com DNS habilitado
- **Subnets Públicas**: 10.0.1.0/24 (us-east-1a) e 10.0.2.0/24 (us-east-1b)
- **Subnets Privadas**: 10.0.3.0/24 (us-east-1a) e 10.0.4.0/24 (us-east-1b)
- **Internet Gateway**: Para subnets públicas
- **2 NAT Gateways**: 1 por AZ para alta disponibilidade
- **Route Tables**: Separadas para subnets públicas e privadas

### Load Balancer
- **ALB**: Subnets públicas, internet-facing
- **2 Target Groups**: 
  - `app-task-frontend-tg` (porta 80, health check `/`)
  - `app-task-backend-tg` (porta 3000, health check `/tasks`)
- **Listener HTTP (80)** com path-based routing:
  - Default action → Frontend
  - Rule `/tasks*` → Backend (priority 100)
- **Health Checks**: Interval 30s, timeout 5s, 2 healthy/unhealthy thresholds

### ECS
- **Cluster**: `app-task-cluster`
- **2 Services**: `app-task-backend-svc` e `app-task-frontend-svc`
- **2 Task Definitions**: `app-task-backend` e `app-task-frontend`
- **Network Mode**: awsvpc
- **Launch Type**: FARGATE
- **Subnets**: Privadas com assign_public_ip = false

### Security Groups
- **ALB SG**: Ingress 80/443 de 0.0.0.0/0, egress all
- **ECS Backend SG**: Ingress 3000 apenas do ALB, egress all
- **ECS Frontend SG**: Ingress 80 apenas do ALB, egress all
- **RDS SG**: Ingress 5432 apenas do ECS Backend, egress all

### RDS
- **Engine**: PostgreSQL 17.6
- **Instance**: db.t3.micro
- **Storage**: 20GB gp2
- **Subnets**: Privadas (DB Subnet Group)
- **SSL**: Obrigatório (rejectUnauthorized: false no cliente)
- **Publicly Accessible**: false
- **Backup**: skip_final_snapshot = true (desenvolvimento)

### Observabilidade
- **CloudWatch Log Groups**:
  - `/ecs/app-task/backend`
  - `/ecs/app-task/frontend`
- **Retenção**: 7 dias
- **Log Driver**: awslogs

### IAM
- **Role**: `app-task-execution-role`
- **Policy**: AmazonECSTaskExecutionRolePolicy
- **Trust**: ecs-tasks.amazonaws.com

## Provisionamento

Infraestrutura gerenciada via **Terraform** em arquivo único `infra/main.tf`:

1. **Provider AWS** (us-east-1)
2. **VPC e Subnets** (4 subnets em 2 AZs)
3. **Gateways** (IGW + 2 NAT)
4. **Route Tables** (1 pública + 2 privadas)
5. **ECS Cluster**
6. **Security Groups** (4 grupos)
7. **ALB + Target Groups + Listener + Rule**
8. **RDS + DB Subnet Group**
9. **IAM Role + Policy Attachment**
10. **CloudWatch Log Groups**
11. **Task Definitions** (backend e frontend)
12. **ECS Services** (backend e frontend)
13. **Outputs** (ALB DNS, RDS endpoint)

## Padrão de nomes

Seguir rigorosamente o arquivo `naming.md`:
- Prefixo: `app-task`
- Separador: hífen (`-`)
- Formato: `app-task-<recurso>-<especificador>`
- Exemplos: `app-task-backend-svc`, `app-task-frontend-tg`, `app-task-alb`

## Boas práticas implementadas

### Segurança
- ✅ Security Groups com princípio de menor privilégio
- ✅ RDS em subnets privadas sem acesso público
- ✅ Conexão SSL obrigatória no PostgreSQL
- ✅ ECS tasks em subnets privadas
- ⚠️ Credenciais hardcoded (migrar para Secrets Manager)

### Rede
- ✅ Multi-AZ para alta disponibilidade
- ✅ 2 NAT Gateways (1 por AZ)
- ✅ Subnets públicas apenas para ALB
- ✅ Subnets privadas para ECS e RDS

### Observabilidade
- ✅ CloudWatch Logs habilitado
- ✅ Health checks configurados
- ⚠️ Container Insights desabilitado (considerar habilitar)
- ⚠️ Sem alarmes configurados (adicionar)

### Custos
- ✅ Fargate (sem EC2 para gerenciar)
- ✅ RDS t3.micro (tier gratuito elegível)
- ⚠️ 2 NAT Gateways (~$65/mês) - considerar 1 NAT para dev
- ⚠️ Sem Auto Scaling (fixo em 1 task)

## Melhorias recomendadas

1. **Segurança**:
   - Migrar credenciais para AWS Secrets Manager
   - Habilitar encryption at rest no RDS
   - Adicionar HTTPS com ACM
   - Implementar WAF no ALB

2. **Observabilidade**:
   - Habilitar Container Insights
   - Criar CloudWatch Alarms (CPU, memória, erros)
   - Configurar SNS para notificações
   - Adicionar X-Ray para tracing

3. **Escalabilidade**:
   - Configurar Auto Scaling (1-3 tasks)
   - Adicionar Application Auto Scaling policies
   - Considerar Aurora Serverless para RDS

4. **Custos**:
   - Usar 1 NAT Gateway em ambiente dev
   - Implementar lifecycle policies no ECR
   - Considerar Savings Plans para Fargate

5. **CI/CD**:
   - Implementar CodePipeline ou GitHub Actions
   - Automatizar deploy com terraform apply
   - Adicionar testes automatizados
