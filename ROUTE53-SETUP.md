# 🌐 Configuração Route53 - App CICD

## 📋 Configuração dos Domínios

### 1️⃣ Verificar Hosted Zone Existente

```bash
# Listar hosted zones
aws route53 list-hosted-zones --query 'HostedZones[?Name==`buildcloud.com.br.`]'

# Se não existir, criar
aws route53 create-hosted-zone \
  --name buildcloud.com.br \
  --caller-reference $(date +%s) \
  --hosted-zone-config Comment="App CICD Domain"
```

### 2️⃣ Obter Name Servers

```bash
# Obter zone ID
ZONE_ID=$(aws route53 list-hosted-zones --query 'HostedZones[?Name==`buildcloud.com.br.`].Id' --output text | cut -d'/' -f3)

# Obter name servers
aws route53 get-hosted-zone --id $ZONE_ID --query 'DelegationSet.NameServers'
```

### 3️⃣ Configurar no Registrador

No painel do seu registrador de domínio (Registro.br, GoDaddy, etc.), configure os name servers obtidos acima.

**Exemplo de Name Servers AWS:**
```
ns-1234.awsdns-12.org
ns-567.awsdns-34.net  
ns-890.awsdns-56.com
ns-123.awsdns-78.co.uk
```

### 4️⃣ Verificar Propagação DNS

```bash
# Verificar se os domínios estão resolvendo
nslookup staging.buildcloud.com.br
nslookup www.buildcloud.com.br

# Ou usar dig
dig staging.buildcloud.com.br
dig www.buildcloud.com.br
```

## 🔧 Configuração Manual (Se Necessário)

Se você já tem os domínios configurados mas eles não estão apontando corretamente:

### Staging Domain
```bash
# Obter CloudFront distribution ID para staging
STAGING_DIST_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items[0]=='staging.buildcloud.com.br'].Id" --output text)

# Obter domain name do CloudFront
STAGING_DOMAIN=$(aws cloudfront get-distribution --id $STAGING_DIST_ID --query 'Distribution.DomainName' --output text)

echo "Staging CloudFront: $STAGING_DOMAIN"
```

### Production Domain  
```bash
# Obter CloudFront distribution ID para production
PROD_DIST_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items[0]=='www.buildcloud.com.br'].Id" --output text)

# Obter domain name do CloudFront
PROD_DOMAIN=$(aws cloudfront get-distribution --id $PROD_DIST_ID --query 'Distribution.DomainName' --output text)

echo "Production CloudFront: $PROD_DOMAIN"
```

## ✅ Validação

### Certificados ACM
```bash
# Verificar status dos certificados
aws acm list-certificates --query 'CertificateSummaryList[?DomainName==`staging.buildcloud.com.br` || DomainName==`www.buildcloud.com.br`]'

# Verificar detalhes de um certificado
aws acm describe-certificate --certificate-arn arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT-ID
```

### Teste de Conectividade
```bash
# Testar HTTPS
curl -I https://staging.buildcloud.com.br
curl -I https://www.buildcloud.com.br

# Verificar certificado SSL
openssl s_client -connect staging.buildcloud.com.br:443 -servername staging.buildcloud.com.br
```

## 🐛 Troubleshooting

### Certificado ACM Pendente
- **Problema**: Certificado fica em "Pending validation"
- **Solução**: Verificar se os registros DNS de validação foram criados no Route53
- **Tempo**: Pode levar até 30 minutos

### Domínio não Resolve
- **Problema**: `nslookup` não encontra o domínio
- **Solução**: Verificar se os name servers estão corretos no registrador
- **Tempo**: Propagação DNS pode levar até 48 horas

### CloudFront não Serve o Conteúdo
- **Problema**: Erro 403 ou 404 no CloudFront
- **Solução**: Verificar se o bucket S3 tem conteúdo e se a policy está correta

### HTTPS Redirect não Funciona
- **Problema**: Site carrega em HTTP mas não redireciona para HTTPS
- **Solução**: Verificar configuração do CloudFront (viewer protocol policy)

## 📞 Comandos Úteis

```bash
# Status completo dos recursos
terraform output

# Listar distribuições CloudFront
aws cloudfront list-distributions --query 'DistributionList.Items[].{Id:Id,Domain:DomainName,Aliases:Aliases.Items}'

# Verificar buckets S3
aws s3 ls | grep app-cicd-frontend

# Status dos certificados
aws acm list-certificates --certificate-statuses ISSUED
```