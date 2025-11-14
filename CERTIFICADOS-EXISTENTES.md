# 🔒 Certificados ACM Existentes - App CICD

## ✅ Situação Atual

Você já tem os domínios e certificados criados:
- ✅ `www.buildcloud.com.br`
- ✅ `staging.buildcloud.com.br`
- ✅ Certificados ACM para ambos

## 🔧 Alteração no Terraform

O Terraform foi ajustado para **usar os certificados existentes** ao invés de criar novos:

```hcl
# ANTES (criava novos certificados)
resource "aws_acm_certificate" "staging" {
  domain_name = "staging.buildcloud.com.br"
  # ...
}

# DEPOIS (usa certificados existentes)
data "aws_acm_certificate" "staging" {
  domain   = "staging.buildcloud.com.br"
  statuses = ["ISSUED"]
}
```

## 🚀 Vantagens

1. **Sem Conflitos**: Não tentará criar certificados duplicados
2. **Mais Rápido**: Não precisa aguardar validação DNS
3. **Sem Erros**: Terraform vai encontrar e usar os existentes
4. **Aproveitamento**: Usa recursos já configurados

## 🔍 Verificação dos Certificados

Antes de rodar o Terraform, você pode verificar se os certificados estão com status "ISSUED":

```bash
# Listar todos os certificados
aws acm list-certificates

# Verificar certificado específico
aws acm list-certificates --query 'CertificateSummaryList[?DomainName==`staging.buildcloud.com.br`]'
aws acm list-certificates --query 'CertificateSummaryList[?DomainName==`www.buildcloud.com.br`]'
```

## ⚠️ Possíveis Cenários

### Certificado com Status "PENDING_VALIDATION"
Se algum certificado estiver pendente:
```bash
# Verificar registros DNS de validação
aws acm describe-certificate --certificate-arn arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT-ID
```

### Certificado não Encontrado
Se o Terraform não encontrar o certificado:
1. Verificar se está na região `us-east-1`
2. Verificar se o domínio está exato
3. Verificar se o status é "ISSUED"

## 🎯 Resultado Final

Após o `terraform apply`:
- CloudFront usará seus certificados existentes
- Domínios apontarão para as novas distribuições CloudFront
- SSL funcionará imediatamente (sem aguardar validação)

## 🔄 Próximos Passos

1. **Rodar Terraform**: `terraform apply`
2. **Aguardar CloudFront**: ~15 minutos para distribuir
3. **Testar Domínios**: Acessar staging.buildcloud.com.br e www.buildcloud.com.br
4. **Configurar GitHub**: Seguir GITHUB-SETUP.md

## 💡 Dica

Os registros DNS dos domínios serão **automaticamente atualizados** pelo Terraform para apontar para as novas distribuições CloudFront. Você não precisa fazer nada manual no Route53.