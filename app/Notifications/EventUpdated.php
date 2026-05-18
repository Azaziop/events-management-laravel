<?php
// app/Notifications/EventUpdated.php
namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue; // optionnel mais recommandé
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use App\Models\Event;

class EventUpdated extends Notification implements ShouldQueue // queue recommandée
{
    use Queueable;

    public function __construct(public Event $event) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
           $eventDate = is_string($this->event->date)
               ? \Carbon\Carbon::parse($this->event->date)
               : $this->event->date;

        return (new MailMessage)
            ->subject('Mise à jour d\'événement - ' . $this->event->title . ' - EventApp')
            ->greeting('Bonjour ' . $notifiable->name . ' !')
            ->line('L\'événement auquel vous participez a été **mis à jour** :')
            ->line('### ' . $this->event->title)
            ->line('')
               ->line('**Date :** ' . $eventDate->format('d/m/Y à H:i'))
            ->line('**Lieu :** ' . $this->event->location)
            ->when($this->event->description, function($mail) {
                return $mail->line('**Description :** ' . $this->event->description);
            })
            ->line('')
            ->action('Voir les détails', url('/dashboard'))
            ->line('Merci de votre participation !')
            ->salutation('Cordialement, L\'équipe EventApp');
    }

    public function toArray(object $notifiable): array
    {
        return ['event_id' => $this->event->id];
    }
}
