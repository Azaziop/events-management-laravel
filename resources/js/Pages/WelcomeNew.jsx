import { useEffect, useState } from 'react';
import { Head, Link } from '@inertiajs/react';
import AppLogoSmall from '@/Components/AppLogoSmall';

function Slider({ recentEvents = [] }) {
  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (!recentEvents || recentEvents.length === 0) return;
    const id = setInterval(() => setIndex(i => (i + 1) % recentEvents.length), 4500);
    return () => clearInterval(id);
  }, [recentEvents]);

  const prev = () => setIndex(i => (i - 1 + recentEvents.length) % recentEvents.length);
  const next = () => setIndex(i => (i + 1) % recentEvents.length);

  if (!recentEvents || recentEvents.length === 0) {
    return <div className="rounded-lg bg-gray-800 p-8 text-center text-white">Aucun événement à afficher</div>;
  }

  return (
    <div className="relative">
      <div className="relative h-64 md:h-80 rounded-lg overflow-hidden">
        {recentEvents.map((ev, i) => (
          <div
            key={ev.id}
            className={`absolute inset-0 transition-transform duration-700 ${i === index ? 'translate-x-0' : i < index ? '-translate-x-full' : 'translate-x-full'}`}>
            {(ev.image_url || ev.image_path) ? (
              <img src={ev.image_url || ev.image_path} alt={ev.title} className="w-full h-full object-cover" />
            ) : (
              <div className="w-full h-full bg-gradient-to-r from-gray-700 to-gray-900" />
            )}
            <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent flex items-end p-6">
              <div className="text-white">
                <h3 className="text-xl font-semibold">{ev.title}</h3>
                <div className="text-sm text-gray-200 mt-1">{new Date(ev.date).toLocaleDateString('fr-FR')}</div>
                <p className="text-sm text-gray-200 mt-2 line-clamp-2">{ev.description}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      <button onClick={prev} type="button" className="absolute left-3 top-1/2 -translate-y-1/2 bg-white/10 hover:bg-white/20 text-white p-2 rounded-full">‹</button>
      <button onClick={next} type="button" className="absolute right-3 top-1/2 -translate-y-1/2 bg-white/10 hover:bg-white/20 text-white p-2 rounded-full">›</button>

      <div className="mt-3 flex justify-center gap-2">
        {recentEvents.map((_, i) => (
          <button key={i} onClick={() => setIndex(i)} className={`w-2 h-2 rounded-full ${i === index ? 'bg-white' : 'bg-white/40'}`} />
        ))}
      </div>
    </div>
  );
}

export default function WelcomeNew({ auth, laravelVersion, phpVersion, recentEvents = [] }) {
  const [endedView, setEndedView] = useState(() => {
    try { return typeof window !== 'undefined' ? window.localStorage.getItem('endedViewMode') || 'badge' : 'badge'; } catch (e) { return 'badge'; }
  });

  useEffect(() => {
    try { window.localStorage.setItem('endedViewMode', endedView); } catch (e) {}
  }, [endedView]);

  return (
    <>
      <Head title="Accueil" />
      <div className="bg-gradient-to-b from-white to-gray-50 min-h-screen text-gray-800">
        <div className="max-w-7xl mx-auto px-4 py-8">
          <header className="flex items-center justify-between py-6">
            <Link href={route('home')} className="flex items-center gap-2">
              <AppLogoSmall />
              {/* <span className="ml-2 font-semibold text-gray-800">EventApp</span> */}
            </Link>

            <nav className="flex gap-3 items-center">
              {auth?.user ? (
                <Link href={route('dashboard')} className="px-3 py-2 rounded bg-[#FF2D20] text-white hover:bg-[#FF2D20]/90">Mon espace</Link>
              ) : (
                <>
                  <Link href={route('login')} className="px-3 py-2 rounded border border-gray-300 text-gray-700 hover:bg-gray-50">Connexion</Link>
                  <Link href={route('register')} className="px-3 py-2 rounded bg-[#FF2D20] text-white hover:bg-[#FF2D20]/90">Inscription</Link>
                </>
              )}
            </nav>
          </header>

          <main>
            <section className="mb-10">
              <div className="rounded-lg overflow-hidden">
                <div className="px-4 py-6 md:px-6 md:py-8 bg-gradient-to-r from-white to-gray-50 rounded-lg border border-gray-200">
                  <div className="max-w-7xl mx-auto">
                    <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-6">
                      <div>
                        <h1 className="text-3xl md:text-4xl font-bold text-gray-800">Bienvenue sur EventApp</h1>
                        <p className="mt-2 text-gray-600">Explorez les événements locaux. Connectez-vous pour participer.</p>
                      </div>
                      <div className="md:w-1/2">
                        <Slider recentEvents={recentEvents} />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </section>

            <section>
              <div className="mb-4 flex items-center justify-between">
                <h2 className="text-2xl font-semibold">Événements récents</h2>
                <div className="flex items-center gap-2">
                  <span className="text-sm text-gray-600 mr-2">Affichage des événements terminés :</span>
                  <button onClick={() => setEndedView('badge')} className={`px-3 py-1 rounded ${endedView === 'badge' ? 'bg-gray-800 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}>Badge</button>
                  <button onClick={() => setEndedView('grayscale')} className={`px-3 py-1 rounded ${endedView === 'grayscale' ? 'bg-gray-800 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}>Grisé</button>
                  <button onClick={() => setEndedView('dim')} className={`px-3 py-1 rounded ${endedView === 'dim' ? 'bg-gray-800 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}>Atténué</button>
                  <button onClick={() => setEndedView('hide')} className={`px-3 py-1 rounded ${endedView === 'hide' ? 'bg-gray-800 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}>Masquer</button>
                </div>
              </div>

              {recentEvents && recentEvents.length > 0 ? (
                (() => {
                  const now = new Date();
                  const upcoming = recentEvents.filter(ev => new Date(ev.date) >= now);
                  const past = recentEvents.filter(ev => new Date(ev.date) < now);

                  return (
                    <div className="space-y-8">
                      {upcoming.length > 0 && (
                        <div>
                          <h3 className="text-lg font-medium mb-3">À venir</h3>
                          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                            {upcoming.map(ev => (
                              <article key={ev.id} className="bg-white text-black rounded-lg shadow overflow-hidden">
                                {(ev.image_url || ev.image_path) ? (
                                  <img src={ev.image_url || ev.image_path} alt={ev.title} className="h-40 w-full object-cover" />
                                ) : (
                                  <div className="h-40 w-full bg-gray-200" />
                                )}
                                <div className="p-4">
                                  <h4 className="font-semibold">{ev.title}</h4>
                                  <div className="text-sm text-gray-600">{new Date(ev.date).toLocaleDateString('fr-FR')}</div>
                                  <div className="text-sm text-gray-600">{ev.location}</div>
                                  <p className="text-sm text-gray-700 mt-2 line-clamp-2">{ev.description}</p>
                                  <div className="mt-3 flex justify-end">
                                    <Link href={route('login', { join_event: ev.id })} className="inline-flex items-center rounded bg-gray-900 px-3 py-2 text-white hover:bg-black" aria-label="Se connecter pour rejoindre cet événement">
                                      Se connecter pour rejoindre
                                    </Link>
                                  </div>
                                </div>
                              </article>
                            ))}
                          </div>
                        </div>
                      )}

                      {past.length > 0 && endedView !== 'hide' && (
                        <div>
                          <h3 className="text-lg font-medium mb-3">Événements terminés</h3>
                          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                            {past.map(ev => {
                              const classes = endedView === 'grayscale' ? 'filter grayscale' : endedView === 'dim' ? 'opacity-60' : '';
                              return (
                                <article key={ev.id} className={`bg-white text-black rounded-lg shadow overflow-hidden ${classes}`}>
                                  <div className="relative">
                                    {(ev.image_url || ev.image_path) ? (
                                      <img src={ev.image_url || ev.image_path} alt={ev.title} className="h-40 w-full object-cover" />
                                    ) : (
                                      <div className="h-40 w-full bg-gray-200" />
                                    )}
                                    {endedView === 'badge' && (
                                      <span className="absolute top-3 right-3 bg-gray-800 text-white px-3 py-1 rounded-full text-xs">Terminé</span>
                                    )}
                                  </div>
                                  <div className="p-4">
                                    <h4 className="font-semibold">{ev.title}</h4>
                                    <div className="text-sm text-gray-600">{new Date(ev.date).toLocaleDateString('fr-FR')}</div>
                                    <div className="text-sm text-gray-600">{ev.location}</div>
                                    <p className="text-sm text-gray-700 mt-2 line-clamp-2">{ev.description}</p>
                                    <div className="mt-3 flex justify-end">
                                      <button disabled title="Cet événement est déjà passé" className="inline-flex items-center rounded bg-gray-300 px-3 py-2 text-gray-600 cursor-not-allowed">
                                        Se connecter pour rejoindre
                                      </button>
                                    </div>
                                  </div>
                                </article>
                              );
                            })}
                          </div>
                        </div>
                      )}
                    </div>
                  );
                })()
              ) : (
                <div className="text-gray-400">Aucun événement récent</div>
              )}
            </section>

          </main>
        </div>
      </div>
    </>
  );
}
