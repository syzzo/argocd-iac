# Requirements
- ACM Certificates for grafana, keycloak and argo endpoints

# Steps to Reproduce
## Deploy EKS cluster using the community module
```bash
cd 1-eks
terraform apply --auto-approve
```

## Setup cluster autoscaler, external dns and aws alb driver
```bash
cd ../2-eks-setup
terraform apply --auto-approve
```

## Launch Argo
You can apply it with a random `var.argo_client_secret`
```bash
cd ../3-argo
terraform apply --auto-approve
```

## Launch Keycloak
```bash
cd ../4-keycloak
terraform apply --auto-approve
```
To increase deployment speed we are going to create a port forwarding, the other option is to wait until keycloak is available and use the external endpoint
```bash
kubectl port-forward svc/keycloak-keycloakx-http -n identity 8081:80
```
This will allow us to use localhost:8081 in `5-authentication-setup/providers.tf`

## Create Keycloak resources (Realm, client, user...)
```bash
cd ../5-authentication-setup
terraform apply --auto-approve
```

## Update Argo to use Keycloak
First you'll need to copy the `var.argo_client_secret` to `3-argo/secrets.auto.tfvars`
And then you can apply
```bash
cd 3-argo
terraform apply --auto-approve
```

## Deploy monitoring stack with Argo
This will deploy prometheus and grafana using their separate helm charts (not kube-prometheus-stack)
```bash
cd 6-observability
terraform apply --auto-approve
```

### Tasks Completed
- [x] Task 1: Deploy a Kubernetes Cluster
- [x] Task 2: Deploy ArgoCD
- [x] Task 3: Deploy Keycloak
- [ ] Optional Task 1: Deploy Traefik as Ingress Controller
- [ ] Optional Task 2: Deploy PostgreSQL
- [x] Optional Task 3: Deploy Monitoring
### Possible Improvements:
- S3 backend
- DynamoDB for terraform lock
- Setup an external database for keycloak
- Keycloak metrics endpoint
- Setup Grafana to use keycloak users
- Operate using gitflow