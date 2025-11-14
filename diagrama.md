graph TD
    subgraph Cliente
        A[Usuário]
    end

    subgraph AWS Cloud (Region)
        subgraph Rede Global
            R53(Route 53: dominio.com) --> CF(CloudFront: Cache/CDN/ACM)
            CF --> |Requisições Estáticas/Assets| S3_FE[S3 Bucket (Front-end)]
        end

        subgraph VPC (Provisionada via Terraform)
            subgraph Subnets Públicas
                CF --> ALB[ALB: Application Load Balancer]
            end

            subgraph Subnets Privadas
                ALB --> ECS_Cluster[ECS Cluster (Fargate/EC2)]
                ECS_Cluster --> ECR[ECR: Repositório Docker]
                ECS_Cluster --> RDS(RDS: Banco de Dados)
            end
        end

        style S3_FE fill:#00A8FF,stroke:#333,stroke-width:2px
        style CF fill:#00A8FF,stroke:#333,stroke-width:2px
        style R53 fill:#00A8FF,stroke:#333,stroke-width:2px
        style ECS_Cluster fill:#FF9900,stroke:#333,stroke-width:2px
        style RDS fill:#FF9900,stroke:#333,stroke-width:2px
        style ALB fill:#0073BB,stroke:#333,stroke-width:2px
    end