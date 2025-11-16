# Runtime Connections and Endpoints

This document captures how each deployed component is wired together once the infrastructure is provisioned **without** relying on the CI/CD pipeline. Use it as a checklist while testing manually.

## AWS Resources

| Output | Source | Purpose |
| ------ | ------ | ------- |
| `eks_cluster_name` | `infra/outputs.tf` | Kubernetes API context used by `kubectl`/Helm when deploying the three services. |
| `rds_endpoint` | `infra/outputs.tf` | Hostname for the PostgreSQL database that backs the backend and worker services. Combine with credentials to form a PostgreSQL connection string: `postgresql://<db_user>:<db_password>@<rds_endpoint>:5432/<db_name>`. |
| `ecr_urls` | `infra/outputs.tf` | List of fully-qualified AWS ECR repositories for `yasn-frontend`, `yasn-backend`, and `yasn-worker`. |

## Application Topology

1. **Frontend ➜ API Gateway**  
   The React frontend calls the REST API using the `REACT_APP_API_BASE_URL` environment variable (see `helm/frontend/values.yaml`). Set it to the invoke URL of the API Gateway stage created from `infra/api_gateway`. Example: `https://<api-id>.execute-api.<region>.amazonaws.com/prod`.

2. **API Gateway ➜ Kubernetes Ingress ➜ Backend Service**  
   API Gateway integrates with the private ingress endpoint that fronts the backend deployment inside EKS (`helm/backend`). Requests are forwarded to the `yasn-backend` service on port `8080`.

3. **Backend ➜ RDS PostgreSQL**  
   The backend uses the environment variables from `helm/backend/values.yaml` (`DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`) to build the PostgreSQL DSN. `DB_HOST` must be set to the `rds_endpoint` output mentioned above.

4. **Backend ➜ DynamoDB / Redis / Cognito**  
   Additional integrations (`DYNAMODB_TABLE_NAME`, `REDIS_HOST`, `COGNITO_*`) are also provided via the backend Helm values file and should be pointed to the relevant AWS resources before deploying.

5. **Worker ➜ Backend Data Stores**  
   The worker reads from the same queues/tables defined for the backend (see `helm/worker/values.yaml`) and shares the RDS + Redis connection information.

6. **Helm Deployments ➜ ECR**  
   Each Helm chart references its matching ECR repository. When testing without CI/CD, manually build and push Docker images to those repositories and run `helm upgrade --install ...` pointing to the chart directories under `helm/`.

## Manual Test Checklist

1. `terraform apply` inside `infra/` and capture the outputs listed above.  
2. Update the Helm `values.yaml` files with the concrete endpoints (API Gateway invoke URL, RDS endpoint, Cognito IDs, etc.).  
3. Build and push Docker images for `frontend`, `backend`, and `worker` to the reported ECR URLs.  
4. Use `kubectl config use-context $(terraform output -raw eks_cluster_name)` to target the cluster, then install/upgrade the Helm charts.  
5. Hit the API Gateway URL from the browser or `curl`—it should proxy through to the backend service running in EKS and read/write data via RDS.
