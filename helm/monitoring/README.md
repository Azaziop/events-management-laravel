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

## Dashboard « namespace » (exercice monitoring)

Dashboard identique à l'exercice avancé avec 4 panneaux :

| Panneau | Métrique |
|---------|----------|
| CPU Usage par Node | CPU des nœuds K8s |
| Memory Usage par Pod | RAM du pod sélectionné |
| Nombre de Restarts | Restarts conteneurs |
| Pods en cours d'exécution | Camembert par namespace |

### Import manuel (rapide)

1. Ouvrir Grafana → **Dashboards** → **New** → **Import**
2. **Upload JSON** : `helm/monitoring/grafana-dashboard-namespace.json`
3. Datasource : **Prometheus**
4. En haut : **Namespace** = `default`, **Pod** = `eventapp-events-management-...`

### Déploiement auto

Le script `./scripts/k8s-monitoring-deploy.sh` installe le dashboard dans **Dashboards → namespace**.

### Filtres pour EventApp

| Variable | Valeur |
|----------|--------|
| Namespace | `default` |
| Pod | `eventapp-events-management-xxxxx` |

**Note :** le panneau « CPU par Node » nécessite **node-exporter** (activé par défaut). Si « No data », redéployez le monitoring puis vérifiez dans Prometheus : `node_cpu_seconds_total`. Désactiver avec `NODE_EXPORTER_ENABLED=false`.

**Restarts à 0** : normal si aucun pod n'a redémarré. Test : `kubectl delete pod -n default -l app.kubernetes.io/name=events-management` puis attendre 30 s.

## Accès depuis votre Mac

### 1. Corriger kubectl (contexte minikube → kind)

```bash
eval "$(./scripts/k8s-env.sh)"
kubectl get pods -n monitoring
```

### 2. Démarrer Grafana + Prometheus (arrière-plan)

```bash
chmod +x scripts/k8s-monitoring-start.sh
./scripts/k8s-monitoring-start.sh
```

| Service | URL | Login |
|---------|-----|-------|
| **Grafana** | http://localhost:30300 | `admin` / `admin` |
| **Prometheus** | http://localhost:9090 | — |

Arrêter les port-forwards :

```bash
./scripts/k8s-monitoring-start.sh stop
```

### Alternative — port-forward manuel (terminal ouvert)

```bash
./scripts/k8s-monitoring-access.sh both
```

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
