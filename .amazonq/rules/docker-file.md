# Regras para Dockerfile - Projeto app-cicd

## Backend
- Imagem base: `public.ecr.aws/docker/library/node:18-slim`.
- Usar `WORKDIR /app`.
- Instalar dependências com `npm ci` ou `npm install --build-from-source`.
- Health check: rota `/tasks`.
- Expor porta 3000.
- Usar variáveis de ambiente para host e credenciais do banco.

## Frontend
- **Hospedagem**: S3 + CloudFront (não usa mais Docker)
- **Arquivos estáticos**: HTML, CSS, JS servidos pelo S3
- **CDN**: CloudFront para cache e HTTPS
- **Domínios**: staging.buildcloud.com.br e www.buildcloud.com.br

## Recomendações gerais
- Evitar multi-stage builds.
- Evitar comandos de permissão complexos.
- Usar camadas simples e diretas.
- Testar containers localmente antes do deploy (`docker run`).
- Definir `CMD` e `ENTRYPOINT` de forma clara.
