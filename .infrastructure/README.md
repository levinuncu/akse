# AKSE Setup

## Voraussetzungen

- Azure CLI
- Terraform
- Docker
- kubectl

## 1. Azure Login

```sh
az login
az account set --subscription "<SUBSCRIPTION_ID>"
```

## 2. Azure-Stack deployen

```sh
cd .infrastructure/terraform
terraform init
terraform apply -var-file="environments/dev.tfvars"
```

## 3. Key Vault Secrets setzen

Diese Secrets werden von External Secrets Operator (ESO) nach Kubernetes gespiegelt.

```sh
az keyvault secret set --vault-name kv-akse-dev --name postgres-password --value "<POSTGRES_PASSWORD>"
az keyvault secret set --vault-name kv-akse-dev --name rabbitmq-password --value "<RABBITMQ_PASSWORD>"
az keyvault secret set --vault-name kv-akse-dev --name rabbitmq-cookie --value "<RABBITMQ_COOKIE>"
```

## 4. Backend Images in ACR bauen und pushen

Bei ACR authentifizieren:

```sh
az acr login --name aksecrdev
```

Backend bauen und pushen:

```sh
docker buildx build --platform linux/amd64 -t aksecrdev.azurecr.io/backend:latest -f ./.build/Dockerfile .
docker push "aksecrdev.azurecr.io/backend:latest"
```

## 5. Zugriff auf Backends

Ingress Public IP ermitteln:

```sh
kubectl get svc -n ingress-nginx
```

Requests:

```sh
curl http://<INGRESS_IP>/backend
```
