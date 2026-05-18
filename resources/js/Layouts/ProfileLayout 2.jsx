import { Link } from '@inertiajs/react';
import AppLogoSmall from '@/Components/AppLogoSmall';

export default function ProfileLayout({ header, children }) {
    return (
        <div className="min-h-screen bg-gray-50">
            <nav className="bg-white shadow-sm">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex h-16 justify-between items-center">
                        <div className="flex items-center">
                            <Link href={route('dashboard')} className="flex items-center gap-2">
                                <div className="inline-flex h-8 w-8 items-center justify-center rounded bg-gray-900 text-white">
                                    E
                                </div>
                                <span className="text-lg font-semibold text-gray-900">Events App</span>
                            </Link>
                        </div>

                        <Link
                            href={route('dashboard')}
                            className="text-sm text-gray-700 hover:text-gray-900"
                        >
                            ← Retour au Dashboard
                        </Link>
                    </div>
                </div>
            </nav>

            {header && (
                <header className="bg-white shadow">
                    <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
                        {header}
                    </div>
                </header>
            )}

            <main>{children}</main>
        </div>
    );
}