# devops-satc
 
- Não sei ainda sobre o que é, vou alterar depois.  

  DevOps é o meio termo entre o desenvolvimento e a infra, focado em oferencer velocidade, performance e menores riscos ao projeto.

[devops-engineer](https://www.redhat.com/pt-br/topics/devops/devops-engineer)

- O que é SRE
  SRE é uma abordagem em que as tarefas são referenciadas a automação de sistemas para torná-los mais rápidos e seguros

[what-is-sre](https://www.redhat.com/pt-br/topics/devops/what-is-sre)

Deploy automatizado para GKE com Build + SonarCloud + Trivy + HPA.

## Visão geral
- Build e análise no workflow `Build` (`.github/workflows/build.yml`)
- Deploy no workflow `Deploy para GKE` (`.github/workflows/deploy.yml`), disparado após o `Build`
- Manifests em `k8s/deployment.yaml` e `k8s/hpa.yaml`

## Pré-requisitos
- Projeto no GCP e cluster GKE criado
- APIs habilitadas: `iam.googleapis.com`, `iamcredentials.googleapis.com`, `container.googleapis.com`
- `gcloud` configurado localmente (para setup do Workload Identity)
- `kubectl` configurado (opcional, apenas para testes manuais)

## Manifests e placeholders
Os YAMLs em `k8s/` usam placeholders que são substituídos no workflow:
- `##K8S_NAMESPACE##`
- `##DOCKER_USERNAME##`
- `##K8S_TAG##`

## Variáveis no GitHub
### Repository Variables (Settings → Secrets and variables → Actions → Variables)
- `GCP_PROJECT_ID` = `project-b2a6f725-ff7b-4b80-b72`
- `GCP_PROJECT_NUMBER` = `163992060318`
- `GKE_CLUSTER_LOCATION` = `us-central1-a`
- `GKE_CLUSTER_NAME` = `cluster-satc-devops`
- `K8S_NAMESPACE` = `satc-devops`

### Repository Secrets (Settings → Secrets and variables → Actions → Secrets)
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `SONAR_TOKEN`

## Setup do Workload Identity (GCP)
Substitua `PROJECT_ID` pelo seu project id real e `PROJECT_NUMBER` pelo seu project number.

### 1) Criar Service Account
```bash
gcloud iam service-accounts create gke-deploy-sa \
	--project=PROJECT_ID \
	--display-name="CI deploy to GKE"
```

### 2) Permissões mínimas para deploy no GKE
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
	--member="serviceAccount:gke-deploy-sa@PROJECT_ID.iam.gserviceaccount.com" \
	--role="roles/container.developer"

gcloud projects add-iam-policy-binding PROJECT_ID \
	--member="serviceAccount:gke-deploy-sa@PROJECT_ID.iam.gserviceaccount.com" \
	--role="roles/iam.serviceAccountUser"
```

### 3) Criar Workload Identity Pool + Provider
```bash
gcloud iam workload-identity-pools create github-pool \
	--project=PROJECT_ID \
	--location="global" \
	--display-name="GitHub pool"

gcloud iam workload-identity-pools providers create-oidc github-provider2 \
	--project=PROJECT_ID \
	--location="global" \
	--workload-identity-pool="github-pool" \
	--display-name="GitHub provider" \
	--issuer-uri="https://token.actions.githubusercontent.com" \
	--allowed-audiences="https://cloud.google.com/iam"
```

### 4) Permitir o repo assumir a Service Account
```bash
gcloud iam service-accounts add-iam-policy-binding \
	gke-deploy-sa@PROJECT_ID.iam.gserviceaccount.com \
	--role roles/iam.workloadIdentityUser \
	--member "principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/ErycMJ/devops-satc"
```

## Fluxo do Deploy
1) Faça push na `main` → dispara `Build` (Sonar + Trivy + Docker build/push)
2) Ao concluir o `Build`, dispara `Deploy para GKE` (aplica manifests)

## Deploy manual (opcional)
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/hpa.yaml
```

## Observações importantes
- O HPA usa CPU, então o cluster precisa de métricas habilitadas.
- O `Deploy` faz `sed` no `k8s/deployment.yaml` durante o workflow para substituir placeholders.
- O `Ingress` usa o host `##DOCKER_USERNAME##.app.devops-satc.online`.

## Checklist rápido
- [ ] Variables e Secrets configurados no GitHub
- [ ] Workload Identity configurado no GCP
- [ ] Service Account com permissão de deploy no GKE
- [ ] Cluster GKE ativo e acessível
