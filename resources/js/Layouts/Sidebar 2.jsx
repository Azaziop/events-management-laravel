// resources/js/Layouts/Sidebar.jsx
import { Link, usePage } from '@inertiajs/react';
import { useMemo } from 'react';
import AppLogoSmall from '@/Components/AppLogoSmall';

// Icônes SVG simples (remplaçables par lucide-react si installé)
function IconDashboard(props){return(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" className={`h-5 w-5 ${props.className||''}`}><path strokeWidth="2" d="M3 13h8V3H3v10zm10 8h8v-6h-8v6zM3 21h8v-6H3v6zm10-8h8V3h-8v10z"/></svg>)}
function IconUsers(props){return(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" className={`h-5 w-5 ${props.className||''}`}><path strokeWidth="2" d="M17 21v-2a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4" strokeWidth="2"/><path strokeWidth="2" d="M23 21v-2a4 4 0 0 0-3-3.87"/><path strokeWidth="2" d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>)}
function IconHome(props){return(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" className={`h-5 w-5 ${props.className||''}`}><path strokeWidth="2" d="M3 12l9-9 9 9"/><path strokeWidth="2" d="M9 21V9h6v12"/></svg>)}
function IconLogout(props){return(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" className={`h-5 w-5 ${props.className||''}`}><path strokeWidth="2" d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path strokeWidth="2" d="M16 17l5-5-5-5"/><path strokeWidth="2" d="M21 12H9"/></svg>)}

function NavLink({ href, active, children, icon: Icon }) {
  return (
    <Link
      href={href}
      className={`flex items-center gap-2 px-3 py-2 rounded transition-colors
        ${active ? 'bg-gray-200 text-gray-900 font-medium' : 'text-gray-700 hover:bg-gray-100'}`}
    >
      {Icon && <Icon className={active ? 'text-gray-900' : 'text-gray-500'} />}
      <span>{children}</span>
    </Link>
  );
}

export default function SidebarLayout({ children }) {
  const { url, component, props } = usePage();
  const authUser = props?.auth?.user ?? null;

  // Active helpers
  const active = useMemo(() => ({
    dashboard: component === 'Dashboard',
    adminUsers: url.startsWith('/admin/users'),
    home: url === '/' || url.startsWith('/home'),
  }), [url, component]);

  return (
    <div className="min-h-screen flex bg-gray-50">
      <aside className="w-64 bg-white border-r flex flex-col">
        {/* Header */}
        <div className="px-4 py-4 border-b">
          <Link href={route('home')}>
            <AppLogoSmall />
          </Link>
        </div>

        {/* Navigation */}
        <nav className="p-4 space-y-4 flex-1">
          <div>
            <div className="px-3 text-xs uppercase tracking-wide text-gray-400 mb-2">Général</div>
            <div className="space-y-1">
              {authUser && (
                <NavLink href={route('dashboard')} active={active.dashboard} icon={IconDashboard}>
                  Dashboard
                </NavLink>
              )}
            </div>
          </div>

          {authUser?.role === 'admin' && (
            <div>
              <div className="px-3 text-xs uppercase tracking-wide text-gray-400 mb-2">Administration</div>
              <div className="space-y-1">
                <NavLink href={route('admin.users.index')} active={active.adminUsers} icon={IconUsers}>
                  Gestion utilisateurs
                </NavLink>
              </div>
            </div>
          )}
        </nav>

        {/* Footer: Profil + Déconnexion */}
        {authUser && (
          <div className="border-t p-4">

            <Link
              href={route('logout')}
              method="post"
              as="button"
              type="button"
              className="w-full inline-flex items-center justify-center gap-2 px-3 py-2 rounded border text-gray-700 hover:bg-gray-50"
            >
              <IconLogout />
              <span>Déconnexion</span>
            </Link>
          </div>
        )}
      </aside>

      <main className="flex-1 min-w-0">
        {children}
      </main>
    </div>
  );
}
