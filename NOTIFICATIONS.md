# 📧 Système de Notifications EventApp

## Vue d'ensemble

Le système de notifications envoie automatiquement des emails aux participants lorsqu'un événement est modifié ou annulé, et notifie tous les utilisateurs lorsqu'un nouvel événement est créé.

## Notifications implémentées

### 0️⃣ **EventCreatedNotification** - Nouveau(x) événement(s)
- **Déclencheur** : Création d'un événement (via page Créer ou Dashboard)
- **Destinataires** : Tous les utilisateurs (comptes existants)
- **Contenu** :
  - Nom de l'événement
  - Date et heure
  - Lieu
  - Description (si présente)
  - Bouton "Voir dans EventApp"

### 1️⃣ **EventUpdated** - Mise à jour d'événement
- **Déclencheur** : Modification d'un événement (titre, date, lieu, description)
- **Destinataires** : Tous les participants inscrits à l'événement
- **Contenu** :
  - Nom de l'événement
  - Nouvelle date et heure
  - Nouveau lieu
  - Description mise à jour (si présente)
  - Bouton "Voir les détails"

### 2️⃣ **EventDeletedNotification** - Annulation d'événement
- **Déclencheur** : Suppression d'un événement
- **Destinataires** : Tous les participants inscrits à l'événement
- **Contenu** :
  - Nom de l'événement annulé
  - Date prévue
  - Lieu prévu
  - Message d'excuse
  - Bouton "Découvrir d'autres événements"
- **Style** : Email avec style "error" (rouge)

### 3️⃣ **ParticipantJoinedNotification** - Nouveau participant
- **Déclencheur** : Un utilisateur rejoint un événement
- **Destinataires** : Le créateur de l'événement uniquement
- **Contenu** :
  - Nom du nouveau participant
  - Nom de l'événement
  - Date et lieu de l'événement
  - Nombre total de participants inscrits
  - Bouton "Voir l'événement"
- **Note** : Pas envoyé si le créateur rejoint son propre événement

### 4️⃣ **ParticipantConfirmationNotification** - Confirmation d'inscription
- **Déclencheur** : Un utilisateur rejoint un événement
- **Destinataires** : Le participant qui vient de s'inscrire
- **Contenu** :
  - Confirmation d'inscription
  - Nom de l'événement
  - Date et heure
  - Lieu
  - Description (si présente)
  - Rappel des notifications futures (mises à jour/annulation)
  - Bouton "Voir mes événements"

## Fonctionnement technique

### ParticipantController

#### Méthode `store()` - Inscription à un événement
```php
// Récupérer le participant
$participant = Auth::user();

// Vérifier si déjà inscrit
$alreadyJoined = $event->participants()->where('user_id', $participant->id)->exists();

// Inscrire
$event->participants()->syncWithoutDetaching([Auth::id()]);

// Notifications (seulement si nouvelle inscription)
if (!$alreadyJoined) {
    // 1. Notifier le créateur
    $creator = $event->creator;
    if ($creator && $creator->id !== $participant->id) {
        $creator->notify(new ParticipantJoinedNotification($event, $participant));
    }
    
    // 2. Confirmer au participant
    $participant->notify(new ParticipantConfirmationNotification($event));
}
```

### EventController

### EventController

#### Méthode `update()`
```php
// Après la mise à jour de l'événement
$participants = $event->participants;
if ($participants->isNotEmpty()) {
    Notification::send($participants, new EventUpdated($event));
}
```

#### Méthode `destroy()`
#### Méthodes `store()` et `storeFromDashboard()`
```php
// Après la création de l'événement
$event = Event::create([...]);
$recipients = User::query()->select('id','name','email')->get();
Notification::send($recipients, new EventCreatedNotification($event));
```
```php
// Récupération des données avant suppression
$participants = $event->participants;
$eventTitle = $event->title;
$eventDate = $event->date;
$eventLocation = $event->location;

// Suppression de l'événement
$event->delete();

// Notification après suppression
if ($participants->isNotEmpty()) {
    Notification::send($participants, new EventDeletedNotification($eventTitle, $eventDate, $eventLocation));
}
```

## Configuration email

Les emails sont envoyés via Gmail SMTP (configuré dans `.env`).

### Variables d'environnement
```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=zaouiazaziop@gmail.com
MAIL_PASSWORD="votre_app_password"
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=zaouiazaziop@gmail.com
MAIL_FROM_NAME="EventApp"
```

## Queues (optionnel mais recommandé)

Les notifications implémentent `ShouldQueue` pour une exécution en arrière-plan.

### Activer les queues
1. Configurer dans `.env` :
```env
QUEUE_CONNECTION=database
```

2. Créer la table jobs :
```bash
php artisan queue:table
php artisan migrate
```

3. Lancer le worker :
```bash
php artisan queue:work
```

## Test des notifications

### Tester manuellement
```bash
php artisan tinker
```

```php
use App\Models\Event;
use App\Models\User;
use App\Notifications\EventCreatedNotification;
use App\Notifications\EventUpdated;
use App\Notifications\EventDeletedNotification;
use App\Notifications\ParticipantJoinedNotification;
use App\Notifications\ParticipantConfirmationNotification;
use Illuminate\Support\Facades\Notification;

// Test création d'événement (tous les users)
Notification::send(User::all(), new EventCreatedNotification($event));

// Test mise à jour
$event = Event::first();
$user = User::first();
Notification::send(collect([$user]), new EventUpdated($event));

// Test annulation
Notification::send(collect([$user]), new EventDeletedNotification($event->title, $event->date, $event->location));

// Test nouveau participant (notification au créateur)
$event = Event::with('creator')->first();
$participant = User::where('email', 'participant@test.com')->first();
$event->creator->notify(new ParticipantJoinedNotification($event, $participant));

// Test confirmation d'inscription (au participant)
$participant->notify(new ParticipantConfirmationNotification($event));
```

## Personnalisation des emails

Les templates d'email sont dans `resources/views/vendor/mail/html/`.

### Header avec logo EventApp
- Fichier : `header.blade.php`
- Logo : Icône calendrier SVG dans cercle bleu
- Branding : "EventApp" en bleu

### Thème
- Fichier : `themes/default.css`
- Couleur principale : `#3b82f6` (bleu)
- Boutons : Bleu avec hover

## Sujets des emails

- **Création** : "Nouvel événement - [Titre] - EventApp"
- **Mise à jour** : "Mise à jour d'événement - [Titre] - EventApp"
- **Annulation** : "Événement annulé - [Titre] - EventApp"
- **Nouveau participant** : "Nouveau participant à votre événement - EventApp"
- **Confirmation inscription** : "Inscription confirmée - [Titre] - EventApp"

## Bonnes pratiques

✅ **Toujours récupérer les participants avant suppression**
✅ **Utiliser les queues pour ne pas bloquer l'interface**
✅ **Tester les notifications avant déploiement**
✅ **Vérifier les emails dans les spams**

## Logs

Les emails sont enregistrés dans `storage/logs/laravel.log` en mode développement.

## Dépannage

### Les emails ne sont pas envoyés
1. Vérifier la configuration SMTP dans `.env`
2. Tester avec : `php artisan tinker` puis `Mail::raw('Test', function($m) { $m->to('email@test.com')->subject('Test'); });`
3. Vérifier les logs : `tail -f storage/logs/laravel.log`

### Les participants ne reçoivent pas d'email
1. Vérifier que l'événement a des participants : `$event->participants`
2. Vérifier les adresses email des utilisateurs
3. Activer le mode debug : `APP_DEBUG=true`

---

**Auteur** : EventApp Team  
**Version** : 1.0  
**Date** : Novembre 2025
