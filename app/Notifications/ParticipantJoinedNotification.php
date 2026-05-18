<?php

namespace App\Notifications;

use App\Models\Event;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ParticipantJoinedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public Event $event,
        public User $participant
    ) {}

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

        $participantsCount = $this->event->participants()->count();

        return (new MailMessage)
            ->subject('Nouveau participant à votre événement - EventApp')
            ->greeting('Bonjour ' . $notifiable->name . ' !')
            ->line('**' . $this->participant->name . '** vient de rejoindre votre événement :')
            ->line('### ' . $this->event->title)
            ->line('')
            ->line('**Date :** ' . $eventDate->format('d/m/Y à H:i'))
            ->line('**Lieu :** ' . $this->event->location)
            ->line('**Participants inscrits :** ' . $participantsCount)
            ->line('')
            ->action('Voir l\'événement', url('/dashboard?show=' . $this->event->id))
            ->line('Merci d\'utiliser EventApp !')
            ->salutation('Cordialement, L\'équipe EventApp');
    }

    /**
     * Get the array representation of the notification.
     */
    public function toArray(object $notifiable): array
    {
        return [
            'event_id' => $this->event->id,
            'participant_id' => $this->participant->id,
        ];
    }
}
