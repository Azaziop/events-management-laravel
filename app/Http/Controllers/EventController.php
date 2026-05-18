<?php
// app/Http/Controllers/EventController.php
namespace App\Http\Controllers;

use App\Models\Event;
use App\Notifications\EventUpdated;
use App\Notifications\EventDeletedNotification;
use App\Notifications\EventCreatedNotification;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use App\Models\User;

class EventController extends Controller
{
    use AuthorizesRequests;

    public function home()
    {
    $events = Event::with('creator')->latest()->take(6)->get();
    return Inertia::render('WelcomeNew', ['recentEvents' => $events]);
    }

    public function index(Request $request)
    {
        $events = Event::query()
            ->with(['participants:id,name,email'])
            ->withCount('participants')
            ->when($request->input('search'), fn ($q, $s) =>
                $q->where(fn($qq)=>$qq->where('title','ilike',"%$s%")->orWhere('location','ilike',"%$s%"))
            )
            ->when($request->input('date'), function($query, $date) {
                return $query->whereDate('date', $date);
            })
            ->latest()
            ->paginate(10)
            ->withQueryString();

        return Inertia::render('Events/Index', [
            'events' => $events,
            'filters' => [
                'search' => $request->input('search'),
                'date' => $request->input('date'),
            ],
        ]);
    }

    public function create()
    {
        return Inertia::render('Events/Create');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => ['required', 'max:200'],
            'date' => ['required', 'date', 'after:now'],
            'location' => ['required', 'max:255'],
            'description' => ['nullable', 'string'],
            'image' => ['nullable', 'image', 'max:2048'],
        ], [
            'date.after' => 'La date de l\'événement doit être dans le futur.',
        ]);

        $path = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('events', 'public');
        }
        $event = Event::create([
            'title' => $data['title'],
            'date' => $data['date'],
            'location' => $data['location'],
            'description' => $data['description'] ?? null,
            'image_path' => $path,
            'creator_id' => Auth::id(),
        ]);

        // Notifier tous les utilisateurs d'un nouvel événement
        $recipients = User::query()->select('id','name','email')->get();
        Log::info('EventCreated: preparing notifications', [
            'event_id' => $event->id,
            'recipients_count' => $recipients->count(),
        ]);
        if ($recipients->isNotEmpty()) {
            Notification::send($recipients, new EventCreatedNotification($event));
            Log::info('EventCreated: notifications dispatched', [
                'event_id' => $event->id,
            ]);
        }

        return to_route('events.index');
    }

    public function edit(Event $event)
    {
        $this->authorize('update', $event);
        $event->load(['participants:id,name,email']);
        return Inertia::render('Events/Edit', ['event' => $event]);
    }

    public function update(Request $request, Event $event)
    {
        $this->authorize('update', $event);

        $data = $request->validate([
            'title' => ['required', 'max:200'],
            'date' => ['required', 'date', 'after:now'],
            'location' => ['required', 'max:255'],
            'description' => ['nullable', 'string'],
            'image' => ['nullable', 'image', 'max:2048'],
            'from' => ['nullable','string'],
        ], [
            'date.after' => 'La date de l\'événement doit être dans le futur.',
        ]);

        if ($request->hasFile('image')) {
            if ($event->image_path) Storage::disk('public')->delete($event->image_path);
            $event->image_path = $request->file('image')->store('events','public');
        }

        $event->fill([
            'title'=>$data['title'],
            'date'=>$data['date'],
            'location'=>$data['location'],
            'description'=>$data['description'] ?? null,
        ])->save();

        // Notifier tous les participants de la mise à jour
        // Charger explicitement les participants pour éviter tout souci de lazy loading
        $participants = $event->participants()->get();
        Log::info('EventUpdated: preparing notifications', [
            'event_id' => $event->id,
            'participants_count' => $participants->count(),
            'emails' => $participants->pluck('email')->all(),
        ]);
        if ($participants->isNotEmpty()) {
            Notification::send($participants, new EventUpdated($event));
            Log::info('EventUpdated: notifications dispatched', [
                'event_id' => $event->id,
                'dispatched_to' => $participants->pluck('email')->all(),
            ]);
        } else {
            Log::warning('EventUpdated: no participants to notify', [
                'event_id' => $event->id,
            ]);
        }

        // Pour la modale du dashboard, on reste sur /dashboard
        if ($request->input('from') === 'dashboard' || $request->filled('edit')) {
            return to_route('dashboard');
        }

        return to_route('dashboard');
    }

    public function destroy(Event $event)
    {
        $this->authorize('delete', $event);

        // Récupérer les participants et les informations de l'événement avant suppression
        $participants = $event->participants;
        $eventTitle = $event->title;
        $eventDate = $event->date;
        $eventLocation = $event->location;

        // Supprimer l'image si elle existe
        if ($event->image_path) {
            Storage::disk('public')->delete($event->image_path);
        }

        // Supprimer l'événement
        $event->delete();

        // Notifier tous les participants de l'annulation
        Log::info('EventDeleted: preparing notifications', [
            'event_title' => $eventTitle,
            'participants_count' => $participants->count(),
            'emails' => $participants->pluck('email')->all(),
        ]);
        if ($participants->isNotEmpty()) {
            Notification::send($participants, new EventDeletedNotification($eventTitle, $eventDate, $eventLocation));
            Log::info('EventDeleted: notifications dispatched', [
                'event_title' => $eventTitle,
                'dispatched_to' => $participants->pluck('email')->all(),
            ]);
        } else {
            Log::warning('EventDeleted: no participants to notify', [
                'event_title' => $eventTitle,
            ]);
        }

        return back();
    }

    public function show(Event $event)
    {
        $event->load(['creator', 'participants:id,name,email']);
        return Inertia::render('Events/Show', ['event' => $event]);
    }

    public function dashboard(Request $request)
    {
        $events = Event::query()
            ->with(['participants:id,name,email']) // <<--- clé pour la participation et les emails
            ->withCount('participants')
            ->when($request->input('search'), fn($q,$s)=>
                $q->where(fn($qq)=>$qq->where('title','ilike',"%$s%")->orWhere('location','ilike',"%$s%"))
            )
            ->latest()
            ->paginate(12)
            ->withQueryString();

        // Map supplémentaire pour frontend: participantsIds + is_past déjà présent via accessor
        $events->getCollection()->transform(function($e){
            $e->participantsIds = $e->participants->pluck('id')->toArray();
            return $e;
        });

        $event = null;
        if ($request->filled('show')) {
            $event = Event::with(['creator', 'participants:id,name,email'])->find($request->input('show'));
            if ($event) { $event->participantsIds = $event->participants->pluck('id')->toArray(); }
        }
        if ($request->filled('edit')) {
            $event = Event::with(['creator', 'participants:id,name,email'])->find($request->input('edit'));
            if ($event) { $event->participantsIds = $event->participants->pluck('id')->toArray(); }
        }

        return Inertia::render('Dashboard', [
            'events'  => $events,
            'event'   => $event,
            'filters' => ['search' => $request->input('search')],
        ]);
    }

    public function storeFromDashboard(Request $request)
    {
        $data = $request->validate([
            'title' => ['required', 'max:200'],
            'date' => ['required', 'date', 'after:now'],
            'location' => ['required', 'max:255'],
            'description' => ['nullable', 'string'],
            'image' => ['nullable', 'image', 'max:2048'],
        ], [
            'date.after' => 'La date de l\'événement doit être dans le futur.',
        ]);

        $path = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('events', 'public');
        }

        $event = Event::create([
            'title'=>$data['title'],
            'date'=>$data['date'],
            'location'=>$data['location'],
            'description'=>$data['description'] ?? null,
            'image_path'=>$path,
            'creator_id'=>Auth::id(),
        ]);

        // Notifier tous les utilisateurs d'un nouvel événement
        $recipients = User::query()->select('id','name','email')->get();
        Log::info('EventCreated: preparing notifications', [
            'event_id' => $event->id,
            'recipients_count' => $recipients->count(),
        ]);
        if ($recipients->isNotEmpty()) {
            Notification::send($recipients, new EventCreatedNotification($event));
            Log::info('EventCreated: notifications dispatched', [
                'event_id' => $event->id,
            ]);
        }

        return to_route('dashboard');
    }
}
