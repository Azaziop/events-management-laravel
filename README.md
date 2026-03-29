# Events Management (Laravel)

Guide rapide pour démarrer l'application.

## Prérequis

- Docker + Docker Compose
- (Optionnel local) PHP 8.2+, Composer, Node.js 20+, PostgreSQL

## Image Docker Hub

- Repository : https://hub.docker.com/r/azaziop/event-management
- Tag disponible : `latest`
- Pull :

```bash
docker pull azaziop/event-management:latest
```

---

## Démarrage recommandé (Docker)

1. Construire et lancer les conteneurs :

```bash
docker compose up -d --build
```

2. Exécuter les migrations :

```bash
docker compose exec backend php artisan migrate --force
```

3. Créer l'admin par défaut :

```bash
docker compose exec backend php artisan db:seed --class=AdminUserSeeder --force
```

4. Corriger les images/storage (lien `public/storage`) :

```bash
docker compose exec backend sh -lc 'rm -f public/storage && php artisan storage:link && php artisan optimize:clear'
```

5. Ouvrir l'application :

- http://localhost:8080

### Compte admin par défaut

- Email : `admin@example.com`
- Mot de passe : `secret`

---

## Commandes utiles

- Voir les logs Docker :

```bash
docker compose logs -f
```

- Vérifier les logs d'un service précis (ex: `nginx`) :

```bash
docker compose logs -f nginx
```

- Entrer dans un conteneur (ex: `backend`) :

```bash
docker compose exec backend sh
```

- Inspecter le réseau Docker du projet :

```bash
docker network inspect events_app-network
```

- Arrêter Docker :

```bash
docker compose down
```
