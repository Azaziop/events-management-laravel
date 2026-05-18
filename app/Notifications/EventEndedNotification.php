<?php

namespace App\Notifications;

use App\Models\Event;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class EventEndedNotification extends Notification implements ShouldQueue
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
            ->subject('Événement terminé - ' . $this->event->title . ' - EventApp')
            ->greeting('Bonjour ' . $notifiable->name . ' !')
            ->line('Merci d\'avoir participé à l\'événement suivant :')
            ->line('### ' . $this->event->title)
            ->line('')
            ->line('**Date :** ' . $eventDate->format('d/m/Y à H:i'))
            ->line('**Lieu :** ' . $this->event->location)
            ->line('')
            ->line('Nous espérons vous revoir très bientôt dans nos prochains événements !')
            ->action('Voir mes événements', url('/dashboard'))
            ->salutation('Cordialement, L\'équipe EventApp');
    }

    public function toArray(object $notifiable): array
    {
        return [
            'event_id' => $this->event->id,
        ];
    }
}
