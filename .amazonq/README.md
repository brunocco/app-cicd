# Amazon Q Jarvis - Projeto app-task

Agente de IA DevOps do projeto **app-task**, responsável por apoiar na automação, provisionamento e manutenção da infraestrutura AWS do projeto.

## 🧩 Stack AWS
- **ECS Fargate** para execução dos containers
- **ECR** para armazenamento das imagens Docker
- **RDS PostgreSQL** para persistência dos dados
- **ALB (Application Load Balancer)** com Target Groups separados para frontend e backend
- **VPC customizada** com subnets públicas e privadas
- **NAT Gateway** e **Internet Gateway**
- **CloudWatch Logs e Insights** para observabilidade
- **Auto Scaling** configurado para 1–3 tasks por serviço

## 🐳 Containers
1. **Backend**: Node.js + Express + PostgreSQL  
   - Porta: `3000`  
   - Health check: `/tasks`
2. **Frontend**: Nginx + HTML/JS  
   - Porta: `80`

## 🧱 Infraestrutura como Código
O projeto utiliza **Terraform** para criação e gerenciamento de:
- VPC, Subnets e NAT Gateway  
- ECS Cluster + Services  
- ECR Repository  
- RDS Instance  
- ALB + Target Groups + Listeners  
- Security Groups e IAM Roles

## 💡 Como iniciar o agente
```bash
q chat --agent jarvis
