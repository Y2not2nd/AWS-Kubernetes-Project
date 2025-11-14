# AWS Kubernetes Project

This is a complete multi-service Kubernetes deployment on AWS using Terraform, Helm, and GitHub Actions CI/CD.

## Project Structure

```
AWS-Kubernetes-Project/
├── helm/                          # Helm charts for services
│   ├── frontend/                  # Frontend service chart
│   ├── backend/                   # Backend service chart
│   └── worker/                    # Worker service chart
├── services/                      # Application code
│   ├── frontend/                  # React frontend
│   ├── backend/                   # Python Flask backend
│   └── worker/                    # Python worker
├── infra/                         # Terraform infrastructure code
│   ├── eks/                       # EKS cluster and node groups
│   ├── rds/                       # RDS database module
│   ├── dynamodb/                  # DynamoDB tables
│   ├── api_gateway/               # API Gateway configuration
│   ├── ecr/                       # ECR repositories
│   ├── opensearch/                # OpenSearch domain
│   ├── s3/                        # S3 buckets
│   └── k8s/                       # Kubernetes manifests
│       ├── ingress/               # Ingress controller
│       └── monitoring/            # Prometheus and Grafana
├── .github/workflows/             # GitHub Actions CI/CD
└── README.md                      # This file
```

## Getting Started

### Prerequisites

- Terraform >= 1.7.0
- AWS CLI configured with credentials
- kubectl configured for EKS
- Helm 3.x
- Docker

### Deployment

1. **Initialize Terraform**
   ```bash
   cd infra
   terraform init
   ```

2. **Plan Infrastructure**
   ```bash
   terraform plan
   ```

3. **Apply Infrastructure**
   ```bash
   terraform apply
   ```

4. **Deploy Services with Helm**
   ```bash
   helm upgrade --install yasn-frontend ./helm/frontend -n frontend-ns
   helm upgrade --install yasn-backend ./helm/backend -n backend-ns
   helm upgrade --install yasn-worker ./helm/worker -n backend-ns
   ```

## CI/CD Pipeline

The project includes a GitHub Actions workflow (`.github/workflows/yasn-ci-cd.yaml`) that:

1. Builds Docker images for all services
2. Pushes images to AWS ECR
3. Deploys services to EKS using Helm

### Setting up CI/CD

1. Store AWS credentials as GitHub Secrets:
   - `AWS_ROLE_TO_ASSUME`: IAM role ARN for OIDC provider

2. Push to `main` branch to trigger the workflow

## Monitoring

Prometheus and Grafana are available for monitoring the cluster. Access Grafana via:

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
```

Default credentials: `admin` / `admin1234`

## Additional Resources

- Terraform modules handle EKS cluster, RDS, DynamoDB, API Gateway, and ECR
- Helm charts manage Kubernetes deployments with auto-scaling
- IRSA (IAM Roles for Service Accounts) configured for external secrets access
- Nginx ingress controller for routing
