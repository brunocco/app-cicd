@echo off
REM Script para deploy manual (desenvolvimento)
REM Para produção, use GitHub Actions

set AWS_REGION=us-east-1
for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set AWS_ACCOUNT_ID=%%i
set ECR_BACKEND=app-cicd-backend
set ENVIRONMENT=%1
if "%ENVIRONMENT%"=="" set ENVIRONMENT=staging

echo === Deploy para ambiente: %ENVIRONMENT% ===

echo === Login no ECR ===
aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com

echo === Build Backend ===
docker build -t %ECR_BACKEND%:%ENVIRONMENT% ./backend

echo === Tag Backend ===
docker tag %ECR_BACKEND%:%ENVIRONMENT% %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_BACKEND%:%ENVIRONMENT%

echo === Push Backend ===
docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_BACKEND%:%ENVIRONMENT%

echo === Deploy Frontend para S3 ===
REM Sync para S3
aws s3 sync frontend/ s3://app-cicd-frontend-%ENVIRONMENT% --delete

echo === Forçar deploy ECS ===
aws ecs update-service --cluster app-cicd-cluster --service app-cicd-backend-svc-%ENVIRONMENT% --force-new-deployment

echo === Deploy completo para %ENVIRONMENT%! ===
if "%ENVIRONMENT%"=="staging" (
    echo Frontend: https://staging.buildcloud.com.br
    echo Backend: http://app-cicd-alb-staging-%AWS_ACCOUNT_ID%.us-east-1.elb.amazonaws.com
) else (
    echo Frontend: https://www.buildcloud.com.br
    echo Backend: http://app-cicd-alb-prod-%AWS_ACCOUNT_ID%.us-east-1.elb.amazonaws.com
)
pause
