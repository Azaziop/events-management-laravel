<?php

namespace App\Notifications;

use App\Models\Event;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class EventCreatedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public Event $event) {}

    /**
     * Get the notification's delivery channels.
     */
    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    /**
     * Get the mail representation of the notification.
     */
    public function toMail(object $notifiable): MailMessage
    {
        $eventDate = is_string($this->event->date)
            ? \Carbon\Carbon::parse($this->event->date)
            : $this->event->date;

        return (new MailMessage)
            ->subject('Nouvel événement - ' . $this->event->title . ' - EventApp')
            ->greeting('Bonjour ' . $notifiable->name . ' !')
            ->line('Un nouvel événement vient d\'être publié :')
            ->line('### ' . $this->event->title)
            ->line('')
            ->line('**Date :** ' . $eventDate->format('d/m/Y à H:i'))
            ->line('**Lieu :** ' . $this->event->location)
            ->when($this->event->description, function ($mail) {
                return $mail->line('**Description :** ' . $this->event->description);
            })
            ->line('')
            ->action('Voir dans EventApp', url('/dashboard'))
            ->line('À bientôt sur EventApp !')
            ->salutation('Cordialement, L\'équipe EventApp');
    }

    /**
     * Get the array representation of the notification.
     */
    public function toArray(object $notifiable): array
    {
        return [
            'event_id' => $this->event->id,
        ];
    }
}
