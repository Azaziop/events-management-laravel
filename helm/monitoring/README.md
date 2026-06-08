# Monitoring Kubernetes — Étape 6

Stack déployée via `./scripts/k8s-monitoring-deploy.sh` :

| Composant | Rôle | Chart Helm |
|-----------|------|------------|
| **Prometheus** | Collecte des métriques (pods, nodes, K8s) | kube-prometheus-stack |
| **Grafana** | Visualisation (dashboards) | kube-prometheus-stack |
| **Alertmanager** | Alertes (règles Prometheus) | kube-prometheus-stack |
| **Loki** | Centralisation des logs | grafana/loki |
| **Promtail** | Collecte logs des pods | grafana/promtail |

## Déploiement

```bash
# Prérequis : cluster kind/minikube actif
./scripts/minikube-setup.sh
./scripts/k8s-monitoring-deploy.sh
```

Jenkins exécute ce script automatiquement après le déploiement de l'application.

**Ordre de déploiement :** Prometheus + Grafana en premier, puis Loki (optionnel sur kind).

Sur kind/Jenkins, si Loki manque de ressources, Grafana et Prometheus restent disponibles.

## Accès Grafana (depuis votre Mac)

Grafana **tourne** dans le cluster, mais le port `30300` n'est pas toujours mappé sur localhost (cluster kind créé avant la config monitoring).

**Solution — dans un terminal, laissez la commande tourner :**

```bash
chmod +x scripts/k8s-monitoring-access.sh
./scripts/k8s-monitoring-access.sh grafana
```

Puis ouvrez **http://localhost:30300** — login `admin` / `admin`.

Prometheus :

```bash
./scripts/k8s-monitoring-access.sh prometheus
# → http://localhost:9090
```

Les deux en même temps :

```bash
./scripts/k8s-monitoring-access.sh both
```

### Accès direct (si port 30300 mappé sur kind)

| | |
|--|--|
| **URL** | http://localhost:30300 |
| **Login** | `admin` |
| **Password** | `admin` |

## Logs EventApp dans Grafana

1. Ouvrir Grafana → **Explore**
2. Choisir la datasource **Loki**
3. Requête :

```logql
{namespace="default", pod=~"eventapp.*"}
```

## Fichiers

| Fichier | Rôle |
|---------|------|
| `kube-prometheus-stack-values.yaml` | Prometheus, Grafana (NodePort 30300), Alertmanager |
| `loki-values.yaml` | Stockage logs (filesystem, léger pour kind) |
| `promtail-values.yaml` | Agent logs sur chaque nœud |

## Alertes

Les règles par défaut de kube-prometheus-stack couvrent :
- pods en crash loop
- nodes not ready
- CPU / mémoire élevés

Consultez **Alertmanager** via Grafana ou :

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-alertmanager 9093:9093
```
