<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class EventDeletedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public $eventTitle;
    public $eventDate;
    public $eventLocation;

    /**
     * Create a new notification instance.
     */
    public function __construct($eventTitle, $eventDate, $eventLocation)
    {
        $this->eventTitle = $eventTitle;
        $this->eventDate = $eventDate;
        $this->eventLocation = $eventLocation;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
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
           $eventDate = is_string($this->eventDate)
               ? \Carbon\Carbon::parse($this->eventDate)
               : $this->eventDate;

        return (new MailMessage)
            ->subject('Événement annulé - ' . $this->eventTitle . ' - EventApp')
            ->error()
            ->greeting('Bonjour ' . $notifiable->name . ' !')
            ->line('Nous vous informons que l\'événement suivant a été **annulé** :')
            ->line('### ' . $this->eventTitle)
            ->line('')
               ->line('**Date prévue :** ' . $eventDate->format('d/m/Y à H:i'))
            ->line('**Lieu :** ' . $this->eventLocation)
            ->line('')
            ->line('Nous nous excusons pour la gêne occasionnée.')
            ->action('Découvrir d\'autres événements', url('/dashboard'))
            ->line('Merci de votre compréhension.')
            ->salutation('Cordialement, L\'équipe EventApp');
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'event_title' => $this->eventTitle,
            'event_date' => $this->eventDate,
            'event_location' => $this->eventLocation,
        ];
    }
}
