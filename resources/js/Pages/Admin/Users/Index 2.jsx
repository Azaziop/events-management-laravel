import { Head, Link, router } from '@inertiajs/react';
import { useState } from 'react';
import SidebarLayout from '@/Layouts/Sidebar';

function Button({ variant = 'default', className = '', ...props }) {
  const base = 'inline-flex items-center justify-center rounded px-3 py-2 text-sm font-medium transition-colors';
  const variants = {
    default: 'bg-blue-600 text-white hover:bg-blue-700',
    outline: 'border border-gray-300 text-gray-700 hover:bg-gray-50',
    danger: 'bg-red-600 text-white hover:bg-red-700',
    secondary: 'bg-gray-800 text-white hover:bg-black',
  };
  return <button className={`${base} ${variants[variant]} ${className}`} {...props} />;
}

function Input({ className = '', ...props }) {
  return (
    <input {...props} className={`mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent ${className}`} />
  );
}

export default function Index({ users, filters = {} }) {
  const rows = Array.isArray(users) ? users : (users?.data ?? []);
  const [showCreate, setShowCreate] = useState(false);
  const [createForm, setCreateForm] = useState({ name: '', email: '', password: '', password_confirmation: '', role: 'user' });
  const [showEdit, setShowEdit] = useState(false);
  const [editForm, setEditForm] = useState({ id: null, name: '', email: '', password: '', password_confirmation: '', role: 'user' });

  const openCreate = () => {
    setCreateForm({ name: '', email: '', password: '', password_confirmation: '', role: 'user' });
    setShowCreate(true);
  };

  const openEdit = (u) => {
    setEditForm({ id: u.id, name: u.name || '', email: u.email || '', password: '', password_confirmation: '', role: u.role || 'user' });
    setShowEdit(true);
  };

  const closeModals = () => {
    setShowCreate(false);
    setShowEdit(false);
  };

  const submitCreate = (e) => {
    e.preventDefault();
    router.post(route('admin.users.store'), createForm, {
      preserveScroll: true,
      onSuccess: () => {
        closeModals();
        router.reload({ only: ['users'] });
      },
    });
  };

  const submitEdit = (e) => {
    e.preventDefault();
    const payload = { ...editForm };
    const id = payload.id;
    if (!payload.password) {
      delete payload.password;
      delete payload.password_confirmation;
    }
    router.put(route('admin.users.update', id), payload, {
      preserveScroll: true,
      onSuccess: () => {
        closeModals();
        router.reload({ only: ['users'] });
      },
    });
  };

  const destroyUser = (u) => {
    if (!confirm(`Supprimer l'utilisateur ${u.name} ?`)) return;
    router.delete(route('admin.users.destroy', u.id), {
      preserveScroll: true,
      onSuccess: () => router.reload({ only: ['users'] }),
    });
  };

  return (
    <SidebarLayout>
      <Head title="Admin - Utilisateurs" />
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-4 sm:px-6 lg:px-8 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Gestion des utilisateurs</h1>
            <p className="mt-1 text-sm text-gray-600">Gérez tous les utilisateurs de la plateforme</p>
          </div>
          <Button onClick={openCreate}>
            <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            Nouvel utilisateur
          </Button>
        </div>
      </header>
      <main className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        <div className="bg-white rounded-lg shadow-sm p-4 mb-6">
          <form method="get" className="flex items-center gap-3">
            <div className="flex-1">
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <svg className="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                </div>
                <input type="text" name="search" defaultValue={filters.search || ''} placeholder="Rechercher par nom ou email..." className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent" onKeyDown={(e) => { if (e.key === 'Enter') e.currentTarget.form.submit(); }} />
              </div>
            </div>
            {filters.search && (<Link href={route('admin.users.index')} className="text-sm text-blue-600 hover:text-blue-800 font-medium">Réinitialiser</Link>)}
          </form>
        </div>
        {rows.length === 0 ? (
          <div className="bg-white rounded-lg shadow-sm p-12 text-center">
            <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
            <h3 className="mt-2 text-sm font-medium text-gray-900">Aucun utilisateur trouvé</h3>
            <p className="mt-1 text-sm text-gray-500">Commencez par créer un nouvel utilisateur.</p>
            <div className="mt-6">
              <Button onClick={openCreate}>Créer un utilisateur</Button>
            </div>
          </div>
        ) : (
          <div className="bg-white rounded-lg shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Utilisateur</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Rôle</th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {rows.map((u) => (
                    <tr key={u.id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center"><span className="text-blue-600 font-medium text-sm">{u.name?.charAt(0).toUpperCase()}</span></div>
                          <div className="ml-4"><div className="text-sm font-medium text-gray-900">{u.name}</div></div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap"><div className="text-sm text-gray-900">{u.email}</div></td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${u.role === 'admin' ? 'bg-purple-100 text-purple-800' : 'bg-green-100 text-green-800'}`}>
                          {u.role === 'admin' ? 'Administrateur' : 'Utilisateur'}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end gap-2">
                          <Button variant="secondary" onClick={() => openEdit(u)} className="!py-1.5 !px-3">Éditer</Button>
                          <Button variant="danger" onClick={() => destroyUser(u)} className="!py-1.5 !px-3">Supprimer</Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
        {users?.links && users.links.length > 3 && (
          <div className="bg-white rounded-lg shadow-sm mt-6 px-4 py-3">
            <nav className="flex justify-center gap-2">
              {users.links.map((link, i) => (
                <Link key={i} href={link.url || '#'} className={`px-4 py-2 border rounded text-sm font-medium ${link.active ? 'bg-blue-50 border-blue-500 text-blue-600' : 'bg-white border-gray-300 text-gray-500 hover:bg-gray-50'}`} dangerouslySetInnerHTML={{ __html: link.label }} preserveState preserveScroll />
              ))}
            </nav>
          </div>
        )}
      </main>
      {showCreate && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md">
            <div className="px-6 py-4 border-b flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">Créer un utilisateur</h3>
              <button onClick={closeModals} className="text-gray-400 hover:text-gray-500"><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" /></svg></button>
            </div>
            <form onSubmit={submitCreate} className="p-6 space-y-4">
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Nom complet</label><Input value={createForm.name} onChange={(e) => setCreateForm({ ...createForm, name: e.target.value })} placeholder="John Doe" required /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Adresse email</label><Input type="email" value={createForm.email} onChange={(e) => setCreateForm({ ...createForm, email: e.target.value })} placeholder="john@example.com" required /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Mot de passe</label><Input type="password" value={createForm.password} onChange={(e) => setCreateForm({ ...createForm, password: e.target.value })} placeholder="••••••••" required /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Confirmer le mot de passe</label><Input type="password" value={createForm.password_confirmation} onChange={(e) => setCreateForm({ ...createForm, password_confirmation: e.target.value })} placeholder="••••••••" required /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Rôle</label><select className="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" value={createForm.role} onChange={(e) => setCreateForm({ ...createForm, role: e.target.value })}><option value="user">Utilisateur</option><option value="admin">Administrateur</option></select></div>
              <div className="flex justify-end gap-3 pt-4 border-t"><Button type="button" variant="outline" onClick={closeModals}>Annuler</Button><Button type="submit">Créer l'utilisateur</Button></div>
            </form>
          </div>
        </div>
      )}
      {showEdit && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md">
            <div className="px-6 py-4 border-b flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">Éditer l'utilisateur</h3>
              <button onClick={closeModals} className="text-gray-400 hover:text-gray-500"><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" /></svg></button>
            </div>
            <form onSubmit={submitEdit} className="p-6 space-y-4">
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Nom complet</label><Input value={editForm.name} onChange={(e) => setEditForm({ ...editForm, name: e.target.value })} required /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Adresse email</label><Input type="email" value={editForm.email} onChange={(e) => setEditForm({ ...editForm, email: e.target.value })} required /></div>
              <div className="bg-blue-50 border border-blue-200 rounded-md p-3"><p className="text-xs text-blue-800">💡 Laissez les champs vides pour ne pas modifier le mot de passe.</p></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Nouveau mot de passe</label><Input type="password" value={editForm.password} onChange={(e) => setEditForm({ ...editForm, password: e.target.value })} placeholder="Laisser vide pour conserver" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Confirmer le mot de passe</label><Input type="password" value={editForm.password_confirmation} onChange={(e) => setEditForm({ ...editForm, password_confirmation: e.target.value })} placeholder="Laisser vide pour conserver" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Rôle</label><select className="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" value={editForm.role} onChange={(e) => setEditForm({ ...editForm, role: e.target.value })}><option value="user">Utilisateur</option><option value="admin">Administrateur</option></select></div>
              <div className="flex justify-end gap-3 pt-4 border-t"><Button type="button" variant="outline" onClick={closeModals}>Annuler</Button><Button type="submit">Mettre à jour</Button></div>
            </form>
          </div>
        </div>
      )}
    </SidebarLayout>
  );
}
