import { useEffect, useMemo, useState, useRef } from 'react';
import { Head, Link, router, usePage } from '@inertiajs/react';
import SidebarLayout from '@/Layouts/Sidebar';
import AppLogoSmall from '@/Components/AppLogoSmall';

function useAuth() {
  const page = usePage();
  return { user: page?.props?.auth?.user ?? null };
}

function useEventsFromProps(props) {
  const paginator = props?.events ?? [];
  const events = Array.isArray(paginator) ? paginator : (paginator?.data ?? []);
  return { events, paginator };
}

function Button({ variant = 'default', className = '', ...props }) {
  const base = 'inline-flex items-center justify-center rounded px-3 py-2 text-sm';
  const variants = {
    default: 'bg-blue-600 text-white hover:bg-blue-700',
    outline: 'border border-gray-300 text-gray-700 hover:bg-gray-50',
    danger: 'bg-red-600 text-white hover:bg-red-700',
    ghost: 'text-gray-700 hover:bg-gray-100',
  };
  return <button className={`${base} ${variants[variant]} ${className}`} {...props} />;
}

function Input(props) {
  return <input {...props} className={`border rounded px-3 py-2 ${props.className || ''}`} />;
}

function formatDateFR(value) {
  const d = new Date(value);
  return isNaN(d.getTime())
    ? value
    : d.toLocaleDateString('fr-FR', {
        day: 'numeric',
        month: 'long',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
}

function toDateInputValue(raw) {
  if (!raw) return '';
  const d = new Date(raw);
  if (isNaN(d.getTime())) return '';

  // Format pour datetime-local: YYYY-MM-DDTHH:MM
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const hours = String(d.getHours()).padStart(2, '0');
  const minutes = String(d.getMinutes()).padStart(2, '0');

  return `${year}-${month}-${day}T${hours}:${minutes}`;
}

function getDateRanges() {
  const today = new Date();
  const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
  const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);
  const startOfNextMonth = new Date(today.getFullYear(), today.getMonth() + 1, 1);
  const endOfNextMonth = new Date(today.getFullYear(), today.getMonth() + 2, 0);

  return {
    today: {
      start: today.toISOString().split('T')[0],
      end: today.toISOString().split('T')[0]
    },
    thisMonth: {
      start: startOfMonth.toISOString().split('T')[0],
      end: endOfMonth.toISOString().split('T')[0]
    },
    nextMonth: {
      start: startOfNextMonth.toISOString().split('T')[0],
      end: endOfNextMonth.toISOString().split('T')[0]
    }
  };
}

function isDateInRange(date, range) {
  if (!date || !range.start || !range.end) return true;
  const eventDate = new Date(date);
  const start = new Date(range.start);
  const end = new Date(range.end);
  return eventDate >= start && eventDate <= end;
}

function DetailsModal({ event, onClose }) {
  if (!event) return null;
  // participants doit être bien chargé côté backend (EventController@dashboard, déjà fait si tu as suivi la correction précédente)
  const participants = event.participants || [];

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded shadow w-full max-w-lg">
        <div className="p-4 border-b flex items-center justify-between">
          <div className="text-lg font-semibold">{event.title}</div>
          <button onClick={onClose} className="px-2 py-1 rounded hover:bg-gray-100">✕</button>
        </div>
        <div className="p-4 space-y-2">
          {(event.image_url || event.image_path) && (
            <div className="h-48 overflow-hidden rounded">
              <img src={event.image_url || event.image_path} alt={event.title} className="w-full h-full object-cover" />
            </div>
          )}
          <div className="text-sm text-gray-600"><strong>Lieu :</strong> {event.location}</div>
          <div className="text-sm text-gray-600"><strong>Date :</strong> {formatDateFR(event.date)}</div>
          <p className="text-gray-800 whitespace-pre-line">{event.description}</p>

          <div className="mt-4">
            <div className="font-semibold mb-2">Liste des participants :</div>
            {participants.length === 0 ? (
              <div className="text-sm text-gray-500">Aucun participant</div>
            ) : (
              <ul className="space-y-1">
                {participants.map((p) => (
                  <li key={p.id} className="text-sm flex items-center gap-2">
                    <span>{p.name}</span>
                    {p.email && (
                      <a
                        href={`mailto:${p.email}`}
                        className="inline-flex items-center text-blue-500 hover:underline ml-1"
                        title={`Contacter ${p.name}`}
                        target="_blank" rel="noopener noreferrer"
                      >
                        <svg className="inline mr-1" width="16" height="16" fill="none" viewBox="0 0 24 24">
                          <path stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4h16v16H4V4zm16 0v3.76L12 14 4 7.76V4"></path>
                        </svg>
                        Email
                      </a>
                    )}
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
        <div className="p-4 border-t flex justify-end">
          <Button variant="outline" onClick={onClose}>Fermer</Button>
        </div>
      </div>
    </div>
  );
}


function EditModal({ initialEvent, onClose, onSubmit }) {
  const [form, setForm] = useState(() => ({
    title: initialEvent?.title || '',
    date: toDateInputValue(initialEvent?.date),
    location: initialEvent?.location || '',
    description: initialEvent?.description || '',
    image: null,
  }));
  const [imagePreview, setImagePreview] = useState(initialEvent?.image_path || null);

  useEffect(() => {
    if (initialEvent) {
      setForm({
        title: initialEvent.title || '',
        date: toDateInputValue(initialEvent.date),
        location: initialEvent.location || '',
        description: initialEvent.description || '',
        image: null,
      });
      setImagePreview(initialEvent.image_url || initialEvent.image_path || null);
    }
  }, [initialEvent]);

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setForm({ ...form, image: file });
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const submit = (e) => {
    e.preventDefault();
    onSubmit(initialEvent.id, form);
  };

  if (!initialEvent) return null;

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded shadow w-full max-w-md max-h-[90vh] overflow-y-auto">
        <div className="p-4 border-b flex items-center justify-between sticky top-0 bg-white">
          <div className="text-lg font-semibold">Modifier l'événement</div>
          <button onClick={onClose} className="px-2 py-1 rounded hover:bg-gray-100">✕</button>
        </div>
        <form onSubmit={submit} className="p-4 space-y-3">
          <div>
            <label className="text-sm text-gray-700">Nom</label>
            <Input className="w-full mt-1"
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              required
            />
          </div>
          <div>
            <label className="text-sm text-gray-700">Date et heure</label>
            <Input
              className="w-full mt-1"
              type="datetime-local"
              value={form.date}
              onChange={(e) => setForm({ ...form, date: e.target.value })}
              min={new Date().toISOString().slice(0, 16)}
              required
            />
          </div>
          <div>
            <label className="text-sm text-gray-700">Lieu</label>
            <Input
              className="w-full mt-1"
              value={form.location}
              onChange={(e) => setForm({ ...form, location: e.target.value })}
              required
            />
          </div>
          <div>
            <label className="text-sm text-gray-700">Description</label>
            <textarea
              rows={4}
              className="w-full mt-1 border rounded px-3 py-2"
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              required
            />
          </div>
          <div>
            <label className="text-sm text-gray-700 block mb-2">Image de l'événement</label>
            {imagePreview && (
              <div className="mb-2 relative h-40 rounded overflow-hidden">
                <img src={imagePreview} alt="Aperçu" className="w-full h-full object-cover" />
              </div>
            )}
            <Input
              type="file"
              accept="image/*"
              onChange={handleImageChange}
              className="w-full"
            />
            <p className="text-xs text-gray-500 mt-1">Formats acceptés: JPG, PNG, GIF</p>
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <Button variant="outline" type="button" onClick={onClose}>Annuler</Button>
            <Button type="submit">Enregistrer</Button>
          </div>
        </form>
      </div>
    </div>
  );
}

function ConfirmDeleteModal({ event, onCancel, onConfirm }) {
  if (!event) return null;
  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded shadow w-full max-w-sm">
        <div className="p-4 border-b text-lg font-semibold">Supprimer l’événement</div>
        <div className="p-4 text-sm text-gray-700">
          Confirmer la suppression de “{event.title}” ?
        </div>
        <div className="p-4 border-t flex justify-end gap-2">
          <Button variant="outline" onClick={onCancel}>Annuler</Button>
          <Button variant="danger" onClick={() => onConfirm(event)}>Supprimer</Button>
        </div>
      </div>
    </div>
  );
}

function EventCard({ event, user, onOpenDetails, onOpenEdit, onOpenDelete, onJoin, endedView }) {
  const isAdmin = user?.role === 'admin';
  const isOwner = user && event.creator_id === user.id;
  const alreadyJoined = user && event.participantsIds.includes(user.id);
  const isPastFromServer = event.is_past === true; // via accessor
  const showJoin = user && !isAdmin && !isOwner && !alreadyJoined && !isPastFromServer;

  // Format date and time
  const eventDate = new Date(event.date);
  const dateOptions = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
  const timeOptions = { hour: '2-digit', minute: '2-digit' };

  // Calculate if event is upcoming, ongoing, or past
  const now = new Date();
  const isUpcoming = eventDate > now;
  const isPast = isPastFromServer || eventDate < now;

  const endedStyleClasses = isPast ? (endedView === 'grayscale' ? 'filter grayscale' : endedView === 'dim' ? 'opacity-60' : '') : '';

  return (
    <div className={`bg-white rounded-lg shadow-sm hover:shadow-md transition-all duration-300 border border-gray-100 overflow-hidden group ${endedStyleClasses}`}>
      <div className="relative">
        {/* Image Container */}
        <div className="h-48 overflow-hidden">
          {(event.image_url || event.image_path) ? (
            <img
              src={event.image_url || event.image_path}
              alt={event.title}
              className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-300"
            />
          ) : (
            <div className="w-full h-full bg-gradient-to-r from-blue-500 to-blue-600 flex items-center justify-center">
              <div className="rounded-full bg-white/10 p-4">
                <svg className="w-12 h-12 text-white opacity-70" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
                </svg>
              </div>
            </div>
          )}
        </div>

        {/* Event Status Badge */}
        <div className="absolute top-4 right-4">
          {isPast ? (
            endedView === 'badge' && (
              <span className="bg-gray-800/80 text-white px-3 py-1 rounded-full text-xs font-medium backdrop-blur-sm">
                Terminé
              </span>
            )
          ) : isUpcoming ? (
            <span className="bg-green-600/80 text-white px-3 py-1 rounded-full text-xs font-medium backdrop-blur-sm">
              À venir
            </span>
          ) : (
            <span className="bg-blue-600/80 text-white px-3 py-1 rounded-full text-xs font-medium backdrop-blur-sm">
              En cours
            </span>
          )}
        </div>
      </div>

      {/* Content */}
      <div className="p-5">
        <div className="space-y-3">
          <h3 className="text-xl font-semibold text-gray-900 group-hover:text-gray-700 transition-colors">
            {event.title}
          </h3>

          {/* Date and Location */}
          <div className="space-y-2">
            <div className="flex items-center gap-2 text-gray-600">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <span className="text-sm">{eventDate.toLocaleDateString('fr-FR', dateOptions)}</span>
            </div>
            <div className="flex items-center gap-2 text-gray-600">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span className="text-sm">{eventDate.toLocaleTimeString('fr-FR', timeOptions)}</span>
            </div>
            <div className="flex items-center gap-2 text-gray-600">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              <span className="text-sm">{event.location}</span>
            </div>
          </div>

          {/* Description */}
          <p className="text-sm text-gray-600 line-clamp-2">{event.description}</p>

          {/* Participants count */}
          <div className="flex items-center gap-2 text-gray-600">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
            <span className="text-sm">{event.participantsIds.length} participants</span>
          </div>
        </div>

        {/* Actions */}
        <div className="mt-5 flex gap-2 justify-end">
          <Button
            variant="ghost"
            onClick={() => onOpenDetails(event.id)}
            className="text-gray-700 hover:text-gray-900"
          >
            Détails
          </Button>

          {/* Bouton rejoindre */}
          {user && !isAdmin && !isOwner && !alreadyJoined && (
            <Button
              variant="default"
              onClick={() => onJoin(event.id)}
              className={`text-white ${isPast ? 'bg-gray-400 cursor-not-allowed' : 'bg-gray-900 hover:bg-black'}`}
              disabled={isPast}
              title={isPast ? 'Cet événement est déjà passé' : 'Rejoindre cet événement'}
            >
              {isPast ? 'Terminé' : 'Rejoindre'}
            </Button>
          )}

          {(isAdmin || isOwner) && (
            <>
              <Button
                variant="outline"
                onClick={() => onOpenEdit(event.id)}
                className="text-gray-600 hover:text-gray-900"
              >
                Modifier
              </Button>
              <Button
                variant="danger"
                onClick={() => onOpenDelete(event)}
                className="text-red-600 hover:text-red-700"
              >
                Supprimer
              </Button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

function CreateEventModal({ onClose, onSubmit }) {
  const [form, setForm] = useState({
    title: '',
    date: '',
    location: '',
    description: '',
    image: null,
  });
  const [imagePreview, setImagePreview] = useState(null);

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setForm({ ...form, image: file });
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const submit = (e) => {
    e.preventDefault();
    onSubmit(form);
  };

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded shadow w-full max-w-md max-h-[90vh] overflow-y-auto">
        <div className="p-4 border-b sticky top-0 bg-white">
          <div className="text-lg font-semibold">Créer un événement</div>
          <div className="text-sm text-gray-600">Remplissez les informations</div>
        </div>
        <form onSubmit={submit} className="p-4 space-y-3">
          <div>
            <label className="text-sm text-gray-700">Nom</label>
            <Input className="w-full mt-1" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} required />
          </div>
          <div>
            <label className="text-sm text-gray-700">Date et heure</label>
            <Input className="w-full mt-1" type="datetime-local" value={form.date} onChange={(e) => setForm({ ...form, date: e.target.value })} min={new Date().toISOString().slice(0, 16)} required />
          </div>
          <div>
            <label className="text-sm text-gray-700">Lieu</label>
            <Input className="w-full mt-1" value={form.location} onChange={(e) => setForm({ ...form, location: e.target.value })} required />
          </div>
          <div>
            <label className="text-sm text-gray-700">Description</label>
            <textarea rows={4} className="w-full mt-1 border rounded px-3 py-2" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} required />
          </div>
          <div>
            <label className="text-sm text-gray-700 block mb-2">Image de l'événement</label>
            {imagePreview && (
              <div className="mb-2 relative h-40 rounded overflow-hidden">
                <img src={imagePreview} alt="Aperçu" className="w-full h-full object-cover" />
              </div>
            )}
            <Input
              type="file"
              accept="image/*"
              onChange={handleImageChange}
              className="w-full"
            />
            <p className="text-xs text-gray-500 mt-1">Formats acceptés: JPG, PNG, GIF</p>
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <Button variant="outline" type="button" onClick={onClose}>Annuler</Button>
            <Button type="submit">Créer</Button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function Dashboard(props) {
  const { user } = useAuth();
  const { events, paginator } = useEventsFromProps(props);

  const [filter, setFilter] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [dateFilter, setDateFilter] = useState('custom'); // 'today', 'thisMonth', 'nextMonth', 'custom'
  const [dateRange, setDateRange] = useState({ start: '', end: '' });
  const [endedView, setEndedView] = useState(() => {
    try { return typeof window !== 'undefined' ? window.localStorage.getItem('endedViewMode') || 'badge' : 'badge'; } catch (e) { return 'badge'; }
  });

  const [showCreate, setShowCreate] = useState(false);
  const [detailsEvent, setDetailsEvent] = useState(null);
  const [editEvent, setEditEvent] = useState(null);
  const [confirmDelete, setConfirmDelete] = useState(null);
  const [showDateMenu, setShowDateMenu] = useState(false);
  const dateMenuRef = useRef(null);

  const normalized = useMemo(
    () =>
      events.map((e) => ({
        ...e,
        participantsIds: (e.participants || []).map((p) => (typeof p === 'object' ? p.id : p)),
      })),
    [events]
  );

  const filtered = useMemo(() => {
    const q = searchTerm.trim().toLowerCase();
    const dateRanges = getDateRanges();

    const matches = (ev) => {
      // Text search
      const name = (ev.title || ev.name || '').toLowerCase();
      const desc = (ev.description || '').toLowerCase();
      const matchesSearch = !q || name.includes(q) || desc.includes(q);

      // Date filtering
      let matchesDate = true;
      if (dateFilter === 'today') {
        matchesDate = isDateInRange(ev.date, dateRanges.today);
      } else if (dateFilter === 'thisMonth') {
        matchesDate = isDateInRange(ev.date, dateRanges.thisMonth);
      } else if (dateFilter === 'nextMonth') {
        matchesDate = isDateInRange(ev.date, dateRanges.nextMonth);
      } else if (dateFilter === 'custom') {
        matchesDate = isDateInRange(ev.date, dateRange);
      }

      // Ended view: hide past events when 'hide'
      let notHidden = true;
      if (endedView === 'hide') {
        const isPast = ev.is_past === true || new Date(ev.date) < new Date();
        notHidden = !isPast;
      }

      return matchesSearch && matchesDate && notHidden;
    };

    if (!user) return normalized.filter(matches);
    if (filter === 'my-events') return normalized.filter((ev) => ev.creator_id === user.id && matches(ev));
    if (filter === 'joined') {
      return normalized.filter((ev) =>
        ev.creator_id !== user.id &&
        ev.participantsIds.includes(user.id) &&
        matches(ev)
      );
    }
    return normalized.filter(matches);
  }, [normalized, user, filter, searchTerm, dateFilter, dateRange, endedView]);

  // ---- Ajoute la fonction participation ----
  const handleJoin = (eventId) => {
    router.post(route('events.join', eventId), {}, {
      preserveScroll: true,
      onSuccess: () => router.reload({ only: ['events'] }),
    });
  };
  // ----------------------------------------

  // ...autres handlers : openDetails, openEdit, closeAll, createEvent, submitEdit, confirmDeleteNow ( inchangés )...

  const openDetails = (id) => {
    router.visit(route('dashboard'), {
      data: { show: id },
      only: ['event', 'events'],
      preserveState: true,
      preserveScroll: true,
      onSuccess: (page) => setDetailsEvent(page.props?.event || null),
    });
  };

  const openEdit = (id) => {
    router.visit(route('dashboard'), {
      data: { edit: id },
      only: ['event', 'events'],
      preserveState: true,
      preserveScroll: true,
      onSuccess: (page) => setEditEvent(page.props?.event || null),
    });
  };

  const closeAll = () => {
    setShowCreate(false);
    setDetailsEvent(null);
    setEditEvent(null);
    setConfirmDelete(null);
    router.visit(route('dashboard'), {
      replace: true,
      only: ['events'],
      preserveState: true,
      preserveScroll: true,
    });
  };

  const createEvent = (form) => {
    const formData = new FormData();
    formData.append('title', form.title);
    formData.append('date', form.date);
    formData.append('location', form.location);
    formData.append('description', form.description);
    if (form.image) {
      formData.append('image', form.image);
    }

    router.post(route('dashboard.events.store'), formData, {
      preserveScroll: true,
      forceFormData: true,
      onSuccess: () => {
        setShowCreate(false);
        router.reload({ only: ['events'] });
      },
    });
  };

  const submitEdit = (id, form) => {
    const formData = new FormData();
    formData.append('title', form.title);
    formData.append('date', form.date);
    formData.append('location', form.location);
    formData.append('description', form.description);
    formData.append('from', 'dashboard');
    formData.append('_method', 'PUT');
    if (form.image) {
      formData.append('image', form.image);
    }

    router.post(route('events.update', id), formData, {
      preserveScroll: true,
      forceFormData: true,
      onSuccess: () => {
        setEditEvent(null);
        router.reload({ only: ['events'] });
      },
    });
  };

  const confirmDeleteNow = (ev) => {
    router.delete(route('events.destroy', ev.id), {
      preserveScroll: true,
      onSuccess: () => {
        setConfirmDelete(null);
        router.reload({ only: ['events'] });
      },
    });
  };

  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const profileMenuRef = useRef(null);

  useEffect(() => {
    function handleClickOutside(event) {
      if (profileMenuRef.current && !profileMenuRef.current.contains(event.target)) {
        setShowProfileMenu(false);
      }
      if (dateMenuRef.current && !dateMenuRef.current.contains(event.target)) {
        setShowDateMenu(false);
      }
    }

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    try { window.localStorage.setItem('endedViewMode', endedView); } catch (e) {}
  }, [endedView]);

  const Layout = ({ children }) => {
    if (user?.role === 'admin') {
      return <SidebarLayout>{children}</SidebarLayout>;
    }

    return (
      <div className="min-h-screen bg-gray-50">
        {children}
      </div>
    );
  };

  return (
    <Layout>
      <Head title="Événements" />
      <header className="bg-white shadow-sm sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 py-4 flex items-center justify-between">
          <Link href={route('dashboard')}>
            <AppLogoSmall />
          </Link>
          <div className="flex items-center gap-4">

            {/* Profile Dropdown */}
            <div className="relative" ref={profileMenuRef}>
              <button
                onClick={() => setShowProfileMenu(!showProfileMenu)}
                className="flex items-center gap-2 text-gray-700 hover:text-gray-900"
              >
                <div className="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center">
                  {user?.name?.[0]?.toUpperCase() || 'U'}
                </div>
                <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                  <path strokeWidth="2" d="M6 9l6 6 6-6"/>
                </svg>
              </button>

              {showProfileMenu && (
                <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50">
                  <Link
                    href={route('profile.edit')}
                    className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                  >
                    Profil
                  </Link>
                  <Link
                    href={route('logout')}
                    method="post"
                    as="button"
                    className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                  >
                    Déconnexion
                  </Link>
                </div>
              )}
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8">
        <div className="space-y-4 mb-6">
          <div className="space-y-4">
            <div className="flex flex-col md:flex-row md:items-center gap-3">
              <Input
                type="text"
                placeholder="Rechercher des événements..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full md:flex-1"
              />
              <div className="relative md:ml-auto" ref={dateMenuRef}>
                <Button
                  variant="outline"
                  onClick={() => setShowDateMenu((v) => !v)}
                  className="inline-flex items-center gap-2 md:whitespace-nowrap"
                >
                  Filtrer par date: { dateFilter === 'today' ? 'Ce jour' : dateFilter === 'thisMonth' ? 'Ce mois' : dateFilter === 'nextMonth' ? 'Mois prochain' : 'Personnalisé' }
                  <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor"><path strokeWidth="2" d="M6 9l6 6 6-6"/></svg>
                </Button>

                {showDateMenu && (
                  <div className="absolute right-0 z-50 mt-2 w-80 bg-white rounded-md shadow-lg ring-1 ring-black/5 p-2">
                    <div className="text-xs text-gray-500 px-2 pb-2">Préréglages</div>
                    <div className="flex flex-col gap-1">
                      <button
                        onClick={() => { setDateFilter('today'); setDateRange({ start: '', end: '' }); setShowDateMenu(false); }}
                        className={`text-left px-3 py-2 rounded ${dateFilter === 'today' ? 'bg-gray-100 text-gray-900' : 'hover:bg-gray-50 text-gray-700'}`}
                      >
                        Ce jour
                      </button>
                      <button
                        onClick={() => { setDateFilter('thisMonth'); setDateRange({ start: '', end: '' }); setShowDateMenu(false); }}
                        className={`text-left px-3 py-2 rounded ${dateFilter === 'thisMonth' ? 'bg-gray-100 text-gray-900' : 'hover:bg-gray-50 text-gray-700'}`}
                      >
                        Ce mois
                      </button>
                      <button
                        onClick={() => { setDateFilter('nextMonth'); setDateRange({ start: '', end: '' }); setShowDateMenu(false); }}
                        className={`text-left px-3 py-2 rounded ${dateFilter === 'nextMonth' ? 'bg-gray-100 text-gray-900' : 'hover:bg-gray-50 text-gray-700'}`}
                      >
                        Mois prochain
                      </button>
                    </div>

                    <div className="my-2 border-t" />
                    <div className="px-2 pb-2 text-xs text-gray-500">Personnalisé</div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-2 px-2 pb-2">
                      <Input
                        type="date"
                        value={dateRange.start}
                        onChange={(e) => { setDateFilter('custom'); setDateRange(prev => ({ ...prev, start: e.target.value })); }}
                      />
                      <Input
                        type="date"
                        value={dateRange.end}
                        onChange={(e) => { setDateFilter('custom'); setDateRange(prev => ({ ...prev, end: e.target.value })); }}
                        min={dateRange.start}
                      />
                    </div>
                    <div className="flex justify-end gap-2 px-2 pb-1">
                      <Button
                        variant="ghost"
                        onClick={() => { setDateFilter('custom'); setDateRange({ start: '', end: '' }); }}
                        className="text-sm"
                      >
                        Réinitialiser
                      </Button>
                      <Button onClick={() => setShowDateMenu(false)} className="text-sm">Appliquer</Button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
          {/* Titre + contrôles d'affichage des événements terminés */}
          <div className="mb-2 flex items-center justify-between">
            <h2 className="text-2xl font-semibold">Événements</h2>
            <div className="flex items-center gap-2">
              <span className="text-sm text-gray-600 mr-2">Affichage des événements terminés :</span>
              <button onClick={() => setEndedView('badge')} className={`px-3 py-1 rounded ${endedView === 'badge' ? 'bg-gray-800 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}>Badge</button>
              <button onClick={() => setEndedView('grayscale')} className={`px-3 py-1 rounded ${endedView === 'grayscale' ? 'bg-gray-800 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}>Grisé</button>
              <button onClick={() => setEndedView('dim')} className={`px-3 py-1 rounded ${endedView === 'dim' ? 'bg-gray-800 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}>Atténué</button>
              <button onClick={() => setEndedView('hide')} className={`px-3 py-1 rounded ${endedView === 'hide' ? 'bg-gray-800 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}>Masquer</button>
            </div>
          </div>
          <div className="flex justify-between items-center flex-wrap gap-4">
            <div className="flex gap-2 flex-wrap">
              <Button variant={filter === 'all' ? 'default' : 'outline'} onClick={() => setFilter('all')} className={filter === 'all' ? 'bg-gray-900' : ''}>
                Tous les événements
              </Button>
              <Button variant={filter === 'my-events' ? 'default' : 'outline'} onClick={() => setFilter('my-events')} className={filter === 'my-events' ? 'bg-gray-900' : ''}>
                Mes événements
              </Button>
              <Button variant={filter === 'joined' ? 'default' : 'outline'} onClick={() => setFilter('joined')} className={filter === 'joined' ? 'bg-gray-900' : ''}>
                Événements rejoints
              </Button>
            </div>
            <Button onClick={() => setShowCreate(true)} className="bg-gray-900 hover:bg-black">
              + Créer un événement
            </Button>
          </div>
        </div>

        {filtered.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-500 text-lg">Aucun événement trouvé</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8">
            {filtered.map((ev) => (
              <EventCard
                key={ev.id}
                event={ev}
                user={user}
                onOpenDetails={openDetails}
                onOpenEdit={openEdit}
                onOpenDelete={setConfirmDelete}
                onJoin={handleJoin}
                endedView={endedView}
              />
            ))}
          </div>
        )}

        {paginator?.links && (
          <div className="flex gap-2 mt-8">
            {paginator.links.map((link, i) => (
              <Link
                key={i}
                href={link.url || '#'}
                className={`px-2 py-1 rounded border ${link.active ? 'bg-gray-200' : ''}`}
                dangerouslySetInnerHTML={{ __html: link.label }}
                preserveState
                preserveScroll
              />
            ))}
          </div>
        )}
      </main>

      {showCreate && <CreateEventModal onClose={closeAll} onSubmit={createEvent} />}
      {detailsEvent && <DetailsModal event={detailsEvent} onClose={closeAll} />}
      {editEvent && <EditModal initialEvent={editEvent} onClose={closeAll} onSubmit={submitEdit} />}
      {confirmDelete && <ConfirmDeleteModal event={confirmDelete} onCancel={() => setConfirmDelete(null)} onConfirm={confirmDeleteNow} />}
    </Layout>
  );
}
