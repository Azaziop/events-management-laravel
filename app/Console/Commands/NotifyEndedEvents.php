<?php

namespace App\Console\Commands;

use App\Models\Event;
use App\Notifications\EventEndedNotification;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Notification;

class NotifyEndedEvents extends Command
{
    protected $signature = 'events:notify-ended';
    protected $description = 'Notifier les participants des événements terminés et marquer comme notifié';

    public function handle(): int
    {
        $now = now();
        $events = Event::with(['participants:id,name,email'])
            ->whereNull('ended_notified_at')
            ->where('date', '<', $now)
            ->limit(100)
            ->get();

        if ($events->isEmpty()) {
            $this->info('Aucun événement à notifier.');
            return self::SUCCESS;
        }

        foreach ($events as $event) {
            $participants = $event->participants;
            if ($participants->isNotEmpty()) {
                Notification::send($participants, new EventEndedNotification($event));
            }
            $event->forceFill(['ended_notified_at' => $now])->save();
            $this->info("Notifié: {$event->title} ({$participants->count()} participants)");
        }

        return self::SUCCESS;
    }
}
