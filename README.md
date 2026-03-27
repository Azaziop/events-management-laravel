# Events Management (Laravel)

Guide rapide pour démarrer l'application.

## Prérequis

- Docker + Docker Compose
- (Optionnel local) PHP 8.2+, Composer, Node.js 20+, PostgreSQL

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

4. Ouvrir l'application :

- http://localhost:8080

### Compte admin par défaut

- Email : `admin@example.com`
- Mot de passe : `secret`

---

## Démarrage en local (sans Docker)

1. Installer les dépendances :

```bash
composer install
npm install
```

2. Configurer l'environnement :

```bash
cp .env.example .env
php artisan key:generate
```

3. Vérifier PostgreSQL dans `.env` (exemple actuel) :

- `DB_CONNECTION=pgsql`
- `DB_HOST=127.0.0.1`
- `DB_PORT=5432`
- `DB_DATABASE=events_db`
- `DB_USERNAME=postgres`
- `DB_PASSWORD=123`

4. Migrer et seeder :

```bash
php artisan migrate
php artisan db:seed --class=AdminUserSeeder
```

5. Lancer l'app :

```bash
php artisan serve --host=127.0.0.1 --port=8001
npm run dev
```

- Backend : http://127.0.0.1:8001

---

## Commandes utiles

- Lancer les tests :

```bash
php artisan test
```

- Voir les logs Docker :

```bash
docker compose logs -f
```

- Arrêter Docker :

```bash
docker compose down
```
