#!/bin/bash

# Script para deploy manual (desenvolvimento)
# Para produção, use GitHub Actions

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_BACKEND="app-cicd-backend"
ENVIRONMENT=${1:-staging}  # staging ou prod

echo "=== Deploy para ambiente: $ENVIRONMENT ==="

echo "=== Login no ECR ==="
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "=== Build Backend ==="
docker build -t $ECR_BACKEND:$ENVIRONMENT ./backend

echo "=== Tag Backend ==="
docker tag $ECR_BACKEND:$ENVIRONMENT $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_BACKEND:$ENVIRONMENT

echo "=== Push Backend ==="
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_BACKEND:$ENVIRONMENT

echo "=== Deploy Frontend para S3 ==="
# Atualizar URL da API no frontend
sed -i "s|const API_BASE_URL = \".*\"|const API_BASE_URL = \"http://app-cicd-alb-$ENVIRONMENT-$AWS_ACCOUNT_ID.us-east-1.elb.amazonaws.com\"|g" frontend/app.js

# Sync para S3
aws s3 sync frontend/ s3://app-cicd-frontend-$ENVIRONMENT --delete

echo "=== Invalidar CloudFront ==="
DISTRIBUTION_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items[0]=='$([[ $ENVIRONMENT == 'staging' ]] && echo 'staging.buildcloud.com.br' || echo 'www.buildcloud.com.br')'].Id" --output text)
if [ ! -z "$DISTRIBUTION_ID" ]; then
    aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"
fi

echo "=== Forçar deploy ECS ==="
aws ecs update-service --cluster app-cicd-cluster --service app-cicd-backend-svc-$ENVIRONMENT --force-new-deployment

echo "=== Deploy completo para $ENVIRONMENT! ==="
echo "Frontend: https://$([[ $ENVIRONMENT == 'staging' ]] && echo 'staging.buildcloud.com.br' || echo 'www.buildcloud.com.br')"
echo "Backend: http://app-cicd-alb-$ENVIRONMENT-$AWS_ACCOUNT_ID.us-east-1.elb.amazonaws.com"
