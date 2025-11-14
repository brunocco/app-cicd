# Padrões de Nomenclatura - Projeto app-cicd

Essas regras garantem consistência e clareza entre os recursos da AWS e os módulos Terraform do projeto **app-task**.

---

## 🌐 Convenções gerais
- **Prefixo do projeto:** `app-cicd`
- **Separador:** hífen (`-`)
- **Formato geral:** `app-cicd-<recurso>-<ambiente>` (ex: `app-cicd-vpc-prod`)
- **Ambientes válidos:** `dev`, `staging`, `prod`
- **Todas as letras em minúsculo**

---

## 🧱 Infraestrutura base (Terraform)
| Recurso | Padrão | Exemplo |
|----------|---------|---------|
| VPC | `app-task-vpc-<env>` | `app-task-vpc-dev` |
| Subnet pública | `app-task-public-subnet-<az>` | `app-task-public-subnet-a` |
| Subnet privada | `app-task-private-subnet-<az>` | `app-task-private-subnet-b` |
| Internet Gateway | `app-task-igw` | `app-task-igw` |
| NAT Gateway | `app-task-natgw-<az>` | `app-task-natgw-a` |
| Route Table | `app-task-rt-<tipo>` | `app-task-rt-private` |

---

## ⚙️ ECS / ECR
| Recurso | Padrão | Exemplo |
|----------|---------|---------|
| Cluster ECS | `app-task-cluster-<env>` | `app-task-cluster-dev` |
| Task Definition | `app-task-<service>-task` | `app-task-backend-task` |
| Service ECS | `app-task-<service>-svc` | `app-task-frontend-svc` |
| Container | `app-task-<service>-container` | `app-task-backend-container` |
| ECR Repository | `app-task-<service>-repo` | `app-task-backend-repo` |

---

## 🧩 Banco de Dados (RDS)
| Recurso | Padrão | Exemplo |
|----------|---------|---------|
| Instância | `app-task-db-<env>` | `app-task-db-dev` |
| Security Group | `app-task-db-sg` | `app-task-db-sg` |
| Subnet Group | `app-task-db-subnet-group` | `app-task-db-subnet-group` |

---

## 🌍 Networking e Segurança
| Recurso | Padrão | Exemplo |
|----------|---------|---------|
| Security Group do ALB | `app-task-alb-sg` | `app-task-alb-sg` |
| Security Group do ECS | `app-task-ecs-sg` | `app-task-ecs-sg` |
| Security Group do RDS | `app-task-rds-sg` | `app-task-rds-sg` |
| Target Group | `app-task-<service>-tg` | `app-task-backend-tg` |
| Listener | `app-task-listener-<port>` | `app-task-listener-80` |
| Load Balancer | `app-task-alb` | `app-task-alb` |

---

## 🧰 Monitoramento e Logs
| Recurso | Padrão | Exemplo |
|----------|---------|---------|
| Log Group ECS | `/ecs/app-task/<service>` | `/ecs/app-task/backend` |
| Log Stream | `app-task-<service>-stream` | `app-task-frontend-stream` |
| Metric Filter | `app-task-<service>-filter` | `app-task-backend-filter` |
| Dashboard | `app-task-dashboard-<env>` | `app-task-dashboard-dev` |

---

## 🧪 Pipelines e Automação
| Recurso | Padrão | Exemplo |
|----------|---------|---------|
| CodePipeline | `app-task-pipeline-<service>` | `app-task-pipeline-backend` |
| CodeBuild Project | `app-task-build-<service>` | `app-task-build-frontend` |
| IAM Role Pipeline | `app-task-role-pipeline` | `app-task-role-pipeline` |
| IAM Role ECS | `app-task-role-ecs` | `app-task-role-ecs` |

---

## 💡 Boas práticas
- Usar **nomes consistentes** em Terraform (`name` e `tags` devem seguir o mesmo padrão).  
- Tag padrão para todos os recursos:
  ```hcl
  tags = {
    Project     = "app-task"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "brunocco"
  }

