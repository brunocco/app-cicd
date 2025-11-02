# Regras de Infraestrutura - Projeto app-task

## Arquitetura
- Plataforma: ECS com Fargate.
- Banco de dados: Amazon RDS (PostgreSQL, t3.micro).
- Container Registry: Amazon ECR.
- Rede: VPC com subnets públicas e privadas.
- Observabilidade: CloudWatch Logs e CloudWatch Container Insights.
- Auto Scaling: mínimo 1, máximo 3 tasks por serviço.

## Recursos obrigatórios
- Application Load Balancer (ALB) com Target Groups para frontend e backend.
- Security Groups separados para ALB, ECS Tasks e RDS.
- Listener HTTP (80) → opcionalmente HTTPS (443) com ACM.
- Cada serviço ECS terá sua própria Task Definition e Service.

## Padrão de nomes
Seguir o arquivo `naming.md`.

## Boas práticas
- Permitir tráfego interno apenas entre grupos específicos.
- Subnets públicas para ALB e privadas para Fargate tasks e RDS.
- Ativar logging no ALB e no ECS.
