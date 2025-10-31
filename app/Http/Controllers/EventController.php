<?php
// app/Http/Controllers/EventController.php
namespace App\Http\Controllers;

use App\Models\Event;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class EventController extends Controller
{
    use AuthorizesRequests;

    public function home()
    {
        $events = Event::with('creator')->latest()->take(6)->get();
        return Inertia::render('Welcome', ['recentEvents' => $events]);
    }

    public function index(Request $request)
    {
        $events = Event::query()
            ->with(['participants:id,name,email'])
            ->withCount('participants')
            ->when($request->input('search'), fn ($q, $s) =>
                $q->where(fn($qq)=>$qq->where('title','ilike',"%$s%")->orWhere('location','ilike',"%$s%"))
            )
            ->latest()
            ->paginate(10)
            ->withQueryString();

        return Inertia::render('Events/Index', [
            'events' => $events,
            'filters' => ['search' => $request->input('search')],
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
            'date' => ['required', 'date'],
            'location' => ['required', 'max:255'],
            'description' => ['nullable', 'string'],
            'image' => ['nullable', 'image', 'max:2048'],
        ]);

        $path = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('events', 'public');
        }
        Event::create([
            'title' => $data['title'],
            'date' => $data['date'],
            'location' => $data['location'],
            'description' => $data['description'] ?? null,
            'image_path' => $path,
            'creator_id' => Auth::id(),
        ]);

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
            'date' => ['required', 'date'],
            'location' => ['required', 'max:255'],
            'description' => ['nullable', 'string'],
            'image' => ['nullable', 'image', 'max:2048'],
            'from' => ['nullable','string'],
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

        // Pour la modale du dashboard, on reste sur /dashboard
        if ($request->input('from') === 'dashboard' || $request->filled('edit')) {
            return to_route('dashboard');
        }

        return to_route('dashboard');
    }

    public function destroy(Event $event)
    {
        $this->authorize('delete', $event);
        if ($event->image_path) Storage::disk('public')->delete($event->image_path);
        $event->delete();
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

        $event = null;
        if ($request->filled('show')) {
            $event = Event::with(['creator', 'participants:id,name,email'])->find($request->input('show'));
        }
        if ($request->filled('edit')) {
            $event = Event::with(['creator', 'participants:id,name,email'])->find($request->input('edit'));
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
            'date' => ['required', 'date'],
            'location' => ['required', 'max:255'],
            'description' => ['nullable', 'string'],
            'image' => ['nullable', 'image', 'max:2048'],
        ]);

        $path = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('events', 'public');
        }

        Event::create([
            'title'=>$data['title'],
            'date'=>$data['date'],
            'location'=>$data['location'],
            'description'=>$data['description'] ?? null,
            'image_path'=>$path,
            'creator_id'=>Auth::id(),
        ]);

        return to_route('dashboard');
    }
}
