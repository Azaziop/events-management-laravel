<?php
// app/Http/Controllers/ParticipantController.php
namespace App\Http\Controllers;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Log;
use App\Models\Event;
use App\Models\User;
use App\Notifications\ParticipantJoinedNotification;
use App\Notifications\ParticipantConfirmationNotification;
use Illuminate\Http\Request;

class ParticipantController extends Controller
{
    public function store(Request $request, \App\Models\Event $event)
{
        // Récupérer le participant (utilisateur actuel)
        /** @var \App\Models\User $participant */
        $participant = Auth::user();

          // Sécurité backend: empêcher l'inscription si l'événement est passé
          if ($event->is_past) {
                return back()->with('error', "Cet événement est déjà passé. L'inscription n'est plus possible.");
          }

        // Vérifier si le participant n'est pas déjà inscrit
        $alreadyJoined = $event->participants()->where('user_id', $participant->id)->exists();

        // Inscrire le participant
        $event->participants()->syncWithoutDetaching([Auth::id()]);

        // Envoyer les notifications seulement si c'est une nouvelle inscription
        if (!$alreadyJoined) {
            // 1. Notifier le créateur de l'événement
            $creator = $event->creator;
            if ($creator && $creator->id !== $participant->id) {
                $creator->notify(new ParticipantJoinedNotification($event, $participant));
                Log::info('ParticipantJoined: notification sent to creator', [
                    'event_id' => $event->id,
                    'creator_email' => $creator->email,
                    'participant_email' => $participant->email,
                ]);
            }

            // 2. Notifier le participant pour confirmer son inscription
            $participant->notify(new ParticipantConfirmationNotification($event));
            Log::info('ParticipantConfirmation: notification sent to participant', [
                'event_id' => $event->id,
                'participant_email' => $participant->email,
            ]);
        }

    // Rediriger vers le dashboard avec message de succès
    return redirect()->route('dashboard')->with('success', 'Inscription confirmée pour l\'événement "' . $event->title . '".');
}


    public function autoJoin(Request $request, Event $event)
    {
        // Cette méthode est appelée après connexion pour rejoindre automatiquement
        return $this->store($request, $event);
    }

    public function destroy(Request $request, Event $event)
    {
        $event->participants()->detach([Auth::id()]);

        return back()->with('success', 'Vous avez quitté cet événement.');
    }
}
