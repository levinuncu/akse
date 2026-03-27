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
cd _infrastructure/azure
terraform init
terraform apply
```

## 3. Key Vault Secrets setzen

Diese Secrets werden von External Secrets Operator (ESO) nach Kubernetes gespiegelt.

```sh
az keyvault secret set --vault-name kv-akse --name postgres-password --value "<POSTGRES_PASSWORD>"
az keyvault secret set --vault-name kv-akse --name rabbitmq-password --value "<RABBITMQ_PASSWORD>"
az keyvault secret set --vault-name kv-akse --name rabbitmq-cookie --value "<RABBITMQ_COOKIE>"
az keyvault secret set --vault-name kv-akse --name keycloak-password --value "<KEYCLOAK_PASSWORD>"
az keyvault secret set --vault-name kv-akse --name keycloak-secret --value "<KEYCLOAK_SECRET>"
```

## 4. Backend Images in ACR bauen und pushen

Bei ACR authentifizieren:

```sh
az acr login --name aksecr
```

Backend bauen und pushen:

```sh
docker buildx build --platform linux/amd64 -t aksecr.azurecr.io/identity-backend:latest -f ./_build/Backend.Dockerfile . --build-arg APP_NAME=identity-backend
docker push "aksecr.azurecr.io/identity-backend:latest"
```

Frontend bauen und pushen:

```sh
docker buildx build --platform linux/amd64 -t aksecr.azurecr.io/frontend:latest -f ./_build/Frontend.Dockerfile .
docker push "aksecr.azurecr.io/frontend:latest"
```

## 5. Platform-Stack deployen

```sh
cd _infrastructure/platform
terraform init
terraform apply
```

## 6. Kubernets mit AKS verbinden

```sh
 az aks get-credentials \
  --resource-group rg-akse \
  --name aks-akse \
  --overwrite-existing
```

## 6. Zugriff auf Backends

Azure Public IP ermitteln:

```sh
az network public-ip show \
  --resource-group rg-akse \
  --name pip-akse \
  --query ipAddress -o tsv
```

Requests:

```sh
curl http://<PUBLIC_IP>/service/identity/v1/api/docs
# or
curl http://identity.pipgroup.de/service/identity/v1/api/docs
# or
curl -H "Host: identity.pipgroup.de" http://<PUBLIC_IP>/service/identity/v1/api/docs
```
