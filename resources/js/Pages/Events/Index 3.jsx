// resources/js/Pages/Events/Index.jsx
import { Head, Link, router } from '@inertiajs/react';
import { useEffect, useState } from 'react';

export default function Index({ events, event: initialEvent = null }) {
  // events = paginator Laravel; rows = tableau
  const rows = Array.isArray(events) ? events : (events?.data ?? []);

  // Etat local pour la modale et l’événement sélectionné
  const [open, setOpen] = useState(false);
  const [selected, setSelected] = useState(initialEvent);

  // Si le serveur renvoie 'event' (optionnel), on ouvre la modale au chargement
  useEffect(() => {
    if (initialEvent) {
      setSelected(initialEvent);
      setOpen(true);
    }
  }, [initialEvent]);

  const openModal = (id) => {
    // Charge uniquement la prop 'event' depuis la même page via une route dédiée
    // Option A: même route avec lazy/partial props
    router.visit(route('events.index'), {
      data: { show: id },          // query ?show=ID pour que le contrôleur renvoie l'event
      only: ['event', 'events'],   // ne recharge que les props nécessaires
      preserveState: true,
      preserveScroll: true,
      onSuccess: (page) => {
        const ev = page.props?.event || null;
        setSelected(ev);
        setOpen(!!ev);
      },
    });
  };

  const closeModal = () => {
    setOpen(false);
    setSelected(null);
    // Nettoie l’URL et recharge les props sans 'event'
    router.visit(route('events.index'), {
      replace: true,
      only: ['events'],
      preserveState: true,
      preserveScroll: true,
    });
  };

  return (
    <div className="p-6">
      <Head title="Événements" />
      <h1 className="text-2xl font-semibold mb-4">Événements</h1>

      {rows.length === 0 ? (
        <p>Aucun événement.</p>
      ) : (
        <ul className="space-y-2">
          {rows.map((e) => (
            <li key={e.id} className="border rounded p-3 flex items-center justify-between">
              <div>
                <div className="font-medium">{e.title}</div>
                <div className="text-sm text-gray-600">{e.location}</div>
              </div>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => openModal(e.id)}
                  className="text-blue-600 hover:underline"
                >
                  Voir
                </button>
                {/* Lien classique si besoin d’ouvrir en page entière */}
                {/* <Link className="text-gray-600" href={route('events.show', e.id)}>Page</Link> */}
              </div>
            </li>
          ))}
        </ul>
      )}

      {/* Pagination simple */}
      <div className="flex gap-2 mt-4">
        {events?.links?.map((link, i) => (
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

      {/* Modal sans lib */}
      {open && selected && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded shadow w-full max-w-lg">
            <div className="p-4 border-b flex items-center justify-between">
              <div className="text-lg font-semibold">{selected.title}</div>
              <button onClick={closeModal} className="px-2 py-1 rounded hover:bg-gray-100">✕</button>
            </div>
            <div className="p-4 space-y-2">
              {selected.image_path && (
                <div className="h-48 overflow-hidden rounded">
                  <img
                    src={selected.image_path}
                    alt={selected.title}
                    className="w-full h-full object-cover"
                  />
                </div>
              )}
              <div className="text-sm text-gray-600">{selected.location}</div>
              <div className="text-sm text-gray-600">
                {new Date(selected.date).toLocaleDateString('fr-FR', {
                  day: 'numeric',
                  month: 'long',
                  year: 'numeric',
                })}
              </div>
              <p className="text-gray-800">
                {selected.description}
              </p>
            </div>
            <div className="p-4 border-t flex justify-end gap-2">
              <button onClick={closeModal} className="px-3 py-2 rounded border">
                Fermer
              </button>
              <Link
                href={route('events.show', selected.id)}
                className="px-3 py-2 rounded bg-gray-800 text-white hover:bg-black"
              >
                Ouvrir la page
              </Link>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
