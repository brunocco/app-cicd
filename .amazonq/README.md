# Amazon Q Jarvis - Projeto app-cicd

Agente de IA DevOps do projeto **app-cicd**, responsável por apoiar na automação, provisionamento e manutenção da infraestrutura AWS do projeto.

## 🧩 Stack AWS

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

### Observabilidade
- **CloudWatch Log Groups**:
  - `/ecs/app-cicd/backend/staging`
  - `/ecs/app-cicd/backend/prod`
- **Retenção**: 7 dias
- **Log Driver**: awslogs
- **Health Checks**: Configurados em ALB e ECS

### Segurança
- **Security Groups** com princípio de menor privilégio
- **RDS** em subnets privadas sem acesso público
- **CloudFront** com Origin Access Control
- **S3 buckets** com acesso restrito
- **IAM Role**: app-cicd-execution-role

## 🐳 Containers

### Backend
- **Imagem**: `public.ecr.aws/docker/library/node:18-slim`
- **Porta**: 3000
- **Health check**: `/tasks`
- **Conexão**: PostgreSQL com SSL
- **Variáveis de ambiente**: DB_HOST, DB_USER, DB_PASSWORD, DB_NAME, DB_PORT

### Frontend
- **Hospedagem**: S3 + CloudFront (não usa mais Docker)
- **Arquivos estáticos**: HTML, CSS, JS servidos pelo S3
- **CDN**: CloudFront para cache e HTTPS
- **API**: Requisições para `/api/*` (roteadas pelo CloudFront para o ALB)

## 🧱 Infraestrutura como Código

O projeto utiliza **Terraform** para criação e gerenciamento de:
- **VPC e Subnets** (4 subnets em 2 AZs)
- **Internet Gateway + NAT Gateways** (2 NATs)
- **Route Tables** (1 pública + 2 privadas)
- **S3 Buckets + Website Configuration** (2 buckets)
- **CloudFront Origin Access Control** (2 OACs)
- **CloudFront Distributions** (2 distribuições)
- **S3 Bucket Policies** (acesso via CloudFront)
- **Route53 Records** (DNS para domínios)
- **Security Groups** (3 grupos)
- **Application Load Balancers** (2 ALBs)
- **Target Groups + Listeners** (2 TGs)
- **ECS Cluster** (compartilhado)
- **RDS Subnet Group + Instances** (2 instâncias)
- **IAM Role + Policy Attachment**
- **CloudWatch Log Groups** (2 grupos)
- **ECS Task Definitions** (2 definições)
- **ECS Services** (2 serviços)

**Arquivo principal**: `infra/main.tf` (~800 linhas)

## 📋 Regras de Infraestrutura

A pasta `rules/` contém as diretrizes do projeto:
- **docker-file.md**: Padrões para Dockerfiles (imagens base, portas, health checks)
- **infraestrutura.md**: Arquitetura AWS (ECS, RDS, ALB, VPC, observabilidade)
- **naming.md**: Convenções de nomenclatura para recursos AWS
- **pipeline.md**: Diretrizes para CI/CD (CodePipeline ou GitHub Actions)

## 🔧 MCP Servers

### postgres-local
Conexão com banco de dados local (Docker Compose)
```bash
postgresql://postgres:postgres@localhost:5432/tasksdb
```

### postgres-aws-staging
Conexão com RDS Staging na AWS (requer SSL)
```bash
postgresql://postgres:postgres@app-cicd-db-staging.cmhcko6u60nk.us-east-1.rds.amazonaws.com:5432/tasksdb?sslmode=require
```

### postgres-aws-prod
Conexão com RDS Production na AWS (requer SSL)
```bash
postgresql://postgres:postgres@app-cicd-db-prod.cmhcko6u60nk.us-east-1.rds.amazonaws.com:5432/tasksdb?sslmode=require
```

### awslabs.ecs-mcp-server
Integração com ECS para gerenciamento de serviços e tasks

## 💡 Ambiente e recursos para rodar o Agente IA:
### Ambiente:
 1. Crie um role SSM:
    - AWS service/ EC2
    - Nome: app-cicd-role-ssm
    - Política: AmazonSSMamagedInstanceCore
>OBS: caso queria que o Agente tenha nivel mais elevado em sua aplicacao como manipular a aplicacao, criacao de servicos entre outros vc tera que acrescentar mais policitas de acondo com o servico que queria que ele manipule. não adiicone policita admin, adicione apenas as policitas dos servicos que vc queira que ele manipule.

 2. Crie uma instância Linux free tier: 
    - Nome: app-cicd-instance-jarvis
    - Linux free tier
    - t2 micro free tier
    - Security group do ALB da aplicação: app-cicd-alb-sg (isso dará acesso ao Agente na aplicação)
    - VPC da aplicação: app-cicd-vpc
    - Sem par de chaves
    - Storage: 15GB
    - Advanced Details: Adicione a role ssm criada anteriormente
    - Adicione esse user data pra instalar tudo que precisaremos:
```bash
#!/bin/bash

#Instalar Docker, Git, jq e AWS CLI
sudo yum update -y
sudo yum install git -y
sudo yum install docker -y
sudo yum install jq -y

#Instalar AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo yum install unzip -y
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/
sudo usermod -a -G docker ec2-user
sudo usermod -a -G docker ssm-user
id ec2-user ssm-user
sudo newgrp docker

#Ativar docker
sudo systemctl enable docker.service
sudo systemctl start docker.service

#Instalar docker compose 2
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose


#Adicionar swap
sudo dd if=/dev/zero of=/swapfile bs=128M count=32
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo echo "/swapfile swap swap defaults 0 0" >> /etc/fstab


#Instalar node e npm
curl -fsSL https://rpm.nodesource.com/setup_21.x | sudo bash -
sudo yum install -y nodejs

#Configurar python 3.11 e uv para uso com mcp servers da aws
sudo dnf install python3.11 -y
sudo ln -sf /usr/bin/python3.11 /usr/bin/python3

sudo -u ec2-user bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/ec2-user/.bashrc
```

 3. Acesse a instência via ssm.
 
```bash
# Troque para usuariopadrão:
sudo su ec2-user

# Entre no Home da maquina:
cd /home/ec2-user/

```

 5. Baixe o Amazon Q cli developer com zip:
    - link: https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-installing-ssh-setup-autocomplete.html 

    - Baixar e instalar:
```bash
# baixar para Linux x86-64:
curl --proto '=https' --tlsv1.2 -sSf "https://desktop-release.q.us-east-1.amazonaws.com/latest/q-x86_64-linux.zip" -o "q.zip"

# Instalar:
# Extrair:
unzip q.zip

# Instalar:
./q/install.sh

# Confirme Yes e enter
# Trabalhar com conta gratuita
# Copie a URL cole em uma nova aba do browser e clique em autorizar
# volte ao bash a instalação foi feita e teste:
 q + Enter
# para sair:
 /q + Enter
```  
    - Gere uma chave ssh:
```bash
ssh-keygen

# Dê Enter até conectar
# Vai gerar uma chave e mostrar o caminho onde esta guardada
```
    - Configuração de usuário,nome e e-mail pro git:
    - Você terá que fazer um fork do meu repositorio ou clonar, se fizer fork tera que remover o origin remoto no ec2. Se clonou meu repositorio, criou um novo repositorio em seu git e fez o push em seu repositorio é so seguir normalmente os passos seguintes.
```bash
git config --global user name "seu nome"
git config --global user email "seu email"
```
    - Configure do git:
```bash
# Copie id rsa.pub
# cat <caminho que gerou no bash onde foi salvo sua chave ssh>
cat /home/ec2-user/.ssh/id_rsa.pub

# Copie a chave do bash
# Acesse seu git:

#Seu usuário > settings > SSH and GPG keys > New SSH Key
#- Nome: chave aws ec2 com ia
#- Key: cole a chave neste campo

# Adicione ssh Key e autorize
```
    - Testar conexão
```bash
ssh-T git@github.com
```
    - Acesse seu repositorio projeto em seu github
    - Clique em clone com SSH, copie o codigo e digite em sua ec2 para clonar:
```bash
git clone CODIGO_DO_CLONE_SSG_DE_SEU_SEPORITORIO

# Aperte Yes para cnfirmar que quer baixar o projeto no ec2

# Lista as pastas do projeto:
ls

#Entre no projeto
cd app-cicd

#Entre na pasta do agente Jarvis:
cd .amazonq/

# Liste todas as pastas do Agente:
ls

# Entre na pasta do agente para confugurar o agente ou deixar como esta no json:
cd cli-agents

# visualizar o arquivo base do Agente com o nano(editor de texto):
nano jarvis.json

# Na pasta contem nome, descrição e o prompt informando o papel para que serve. tambem contem o tools(informa que ele tem acesso a todas ferramentas) e o resource com todos os arquivos que ele foi treinado, ou seja arquivos referencia para que ele possa atuar sua função.

#Saia do nano:
Ctrl + X

# Em rules tem as regras para o Agente Seguir(recomentdo que leia para entender as regras e informações que ele terá como base)

# Volte a pasta raiz app-cicd:
cd ..
cd ..

```

## Como usar o agente Jarvis
- Na pasta raiz digite:

```bash
# Iniciar chat com o agente
q chat --agent "jarvis"

# Exemplos de comandos:
# - "Revise a configuração do Terraform"
# - "Sugira melhorias de segurança"
# - "Como otimizar custos da infraestrutura?"
# - "Explique o roteamento do ALB"
# - "Verifique os logs do backend"
# - "Crie mais um security group"
```
>Obs: Ao terminar de usar o agente e testar o projeto e agora deseja desprovisionar toda infraestrutura. primeiro apague a instancia criada para manupulação do agente antes de usar o "terraform destroy" para não causar falha, pois a instancia foi provisionada fora do terraform.

## 📚 Documentação

- **README.md**: Guia completo de apresentação e replicação e troubleshooting

## 🎯 Responsabilidades do Jarvis

1. Revisar código Terraform e sugerir melhorias
2. Validar configurações de segurança (Security Groups, IAM)
3. Otimizar custos (NAT Gateway, RDS, ECS)
4. Sugerir implementações de CI/CD
5. Auxiliar em troubleshooting de infraestrutura
6. Garantir conformidade com as regras do projeto
7. Propor melhorias de observabilidade e monitoramento
