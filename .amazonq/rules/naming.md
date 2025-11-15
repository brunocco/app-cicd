# Padrões de Nomenclatura - Projeto app-cicd

Essas regras garantem consistência e clareza entre os recursos da AWS e os módulos Terraform do projeto **app-cicd**.

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
| VPC | `app-cicd-vpc-<env>` | `app-cicd-vpc-dev` |
| Subnet pública | `app-cicd-public-subnet-<az>` | `app-cicd-public-subnet-a` |
| Subnet privada | `app-cicd-private-subnet-<az>` | `app-cicd-private-subnet-b` |
| Internet Gateway | `app-cicd-igw` | `app-cicd-igw` |
| NAT Gateway | `app-cicd-natgw-<az>` | `app-cicd-natgw-a` |
| Route Table | `app-cicd-rt-<tipo>` | `app-cicd-rt-private` |

---

## ⚙️ ECS / ECR
| Recurso | Padrão | Exemplo |
|----------|---------|---------|
| Cluster ECS | `app-cicd-cluster-<env>` | `app-cicd-cluster-dev` |
| Task Definition | `app-cicd-<service>-task` | `app-cicd-backend-task` |
| Service ECS | `app-cicd-<service>-svc` | `app-cicd-frontend-svc` |
| Container | `app-cicd-<service>-container` | `app-cicd-backend-container` |
| ECR Repository | `app-cicd-<service>-repo` | `app-cicd-backend-repo` |

---

## 🧩 Banco de Dados (RDS)
| Recurso | Padrão | Exemplo |
|----------|---------|---------|
| Instância | `app-cicd-db-<env>` | `app-cicd-db-dev` |
| Security Group | `app-cicd-db-sg` | `app-cicd-db-sg` |
| Subnet Group | `app-cicd-db-subnet-group` | `app-cicd-db-subnet-group` |

---

## 🌍 Networking e Segurança
| Recurso | Padrão | Exemplo |
|----------|---------|---------|
| Security Group do ALB | `app-cicd-alb-sg` | `app-cicd-alb-sg` |
| Security Group do ECS | `app-cicd-ecs-sg` | `app-cicd-ecs-sg` |
| Security Group do RDS | `app-cicd-rds-sg` | `app-cicd-rds-sg` |
| Target Group | `app-cicd-<service>-tg` | `app-cicd-backend-tg` |
| Listener | `app-cicd-listener-<port>` | `app-cicd-listener-80` |
| Load Balancer | `app-cicd-alb` | `app-cicd-alb` |

---

## 🧰 Monitoramento e Logs
| Recurso | Padrão | Exemplo |
|----------|---------|---------|
| Log Group ECS | `/ecs/app-cicd/<service>` | `/ecs/app-cicd/backend` |
| Log Stream | `app-cicd-<service>-stream` | `app-cicd-frontend-stream` |
| Metric Filter | `app-cicd-<service>-filter` | `app-cicd-backend-filter` |
| Dashboard | `app-cicd-dashboard-<env>` | `app-cicd-dashboard-dev` |

---

## 🧪 Pipelines e Automação
| Recurso | Padrão | Exemplo |
|----------|---------|---------|
| CodePipeline | `app-cicd-pipeline-<service>` | `app-cicd-pipeline-backend` |
| CodeBuild Project | `app-cicd-build-<service>` | `app-cicd-build-frontend` |
| IAM Role Pipeline | `app-cicd-role-pipeline` | `app-cicd-role-pipeline` |
| IAM Role ECS | `app-cicd-role-ecs` | `app-cicd-role-ecs` |

---

## 💡 Boas práticas
- Usar **nomes consistentes** em Terraform (`name` e `tags` devem seguir o mesmo padrão).  
- Tag padrão para todos os recursos:
  ```hcl
  tags = {
    Project     = "app-cicd"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "brunocco"
  }

