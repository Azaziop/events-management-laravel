# EventApp — Déploiement Kubernetes local (Étape 5)

Déploiement de l'application sur **Minikube** avec **Helm**, en reprenant l'architecture ECS (nginx + backend sidecar).

## Architecture

```
NodePort :30080
    └── Pod (sidecar)
          ├── nginx:80        → fichiers statiques (emptyDir partagé)
          └── backend:9000    → PHP-FPM + migrations au démarrage
    └── PostgreSQL 16 (Deployment + PVC)
```

## Prérequis

| Outil | Installation (macOS) |
|-------|----------------------|
| [Minikube](https://minikube.sigs.k8s.io/docs/start/) | `brew install minikube` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `brew install kubectl` |
| [Helm](https://helm.sh/docs/intro/install/) | `brew install helm` |
| Docker | Déjà utilisé par Jenkins |

## 1. Préparer Minikube

```bash
chmod +x scripts/minikube-setup.sh scripts/k8s-deploy.sh
./scripts/minikube-setup.sh
```

## 2. Déployer l'application

### Option A — Image Jenkins (Docker Hub)

```bash
export IMAGE_TAG=23-f681023   # tag du dernier build Jenkins
./scripts/k8s-deploy.sh
```

### Option B — Image locale (build manuel)

```bash
eval $(minikube docker-env)
docker build -t azaziop/event-management1:local .
export IMAGE_TAG=local
./scripts/k8s-deploy.sh
```

## 3. Accéder à l'application

```bash
minikube service eventapp-events-management --url
# ou http://$(minikube ip):30080
```

**Admin :** `admin@example.com` / `secret`

## 4. Commandes utiles

```bash
# Statut
kubectl get pods,svc,pvc -l app.kubernetes.io/instance=eventapp

# Logs backend
kubectl logs -l app.kubernetes.io/instance=eventapp -c backend -f

# Redéployer une nouvelle image
IMAGE_TAG=<nouveau-tag> ./scripts/k8s-deploy.sh

# Désinstaller
helm uninstall eventapp
```

## 5. CI/CD Jenkins

Le pipeline Jenkins inclut un stage **« Déploiement Kubernetes »** exécuté automatiquement sur les branches `master` / `main` (ou sur un tag Git), après le push Docker Hub.

**Jenkins-in-Docker :** Minikube ne fonctionne pas (SSH sur localhost de l'hôte). Le pipeline utilise automatiquement **kind** à la place.

**Développement local (Mac) :** Minikube reste le choix par défaut via `./scripts/minikube-setup.sh`.

Prérequis sur l'agent Jenkins : **Docker** avec le socket monté (`-v /var/run/docker.sock:/var/run/docker.sock`). Les binaires sont installés automatiquement.

**Premier build :** création du cluster kind (~2–5 min). Les builds suivants réutilisent le cluster.

Pour forcer le mode : `K8S_CLUSTER=kind` ou `K8S_CLUSTER=minikube`. Pour désactiver : `DEPLOY_MINIKUBE=false`.

## Monitoring — Étape 6 (Kubernetes)

Voir [helm/monitoring/README.md](../monitoring/README.md).

- **Grafana** : http://localhost:30300 (`admin` / `admin`)
- **Prometheus** : métriques cluster + pods EventApp
- **Loki** : logs centralisés des pods
- Déployé automatiquement par Jenkins après l'application

## Fichiers du chart

| Fichier | Rôle |
|---------|------|
| `values.yaml` | Valeurs par défaut |
| `values.minikube.yaml` | Overrides locaux (APP_KEY, NodePort) |
| `templates/deployment-app.yaml` | Pod nginx + backend sidecar |
| `templates/deployment-postgres.yaml` | PostgreSQL 16 |
| `templates/service-app.yaml` | NodePort 30080 |
| `templates/secret.yaml` | APP_KEY, DB_PASSWORD |

## Migration vers le cloud

Ce chart est compatible EKS/AKS/GKE : remplacez `values.minikube.yaml` par des valeurs cloud (RDS externe, Ingress, ECR image, etc.).
