// resources/js/Pages/Auth/Login.jsx
import { Head, Link, useForm } from '@inertiajs/react';
import { EnvelopeIcon, LockClosedIcon, ArrowRightOnRectangleIcon } from '@heroicons/react/24/outline';

export default function Login({ status, canResetPassword }) {
  const { data, setData, post, processing, errors, reset } = useForm({
    email: '',
    password: '',
    remember: false,
  });

  const submit = (e) => {
    e.preventDefault();
    post(route('login'), {
      onFinish: () => reset('password'),
    });
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 p-4">
      <Head title="Connexion - EventApp" />
      <div className="w-full max-w-md bg-white rounded shadow p-6">
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-blue-100 mb-3">
            <svg className="w-10 h-10 text-blue-600" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
            </svg>
          </div>
          <h1 className="text-3xl font-bold text-blue-600 mb-2">EventApp</h1>
        </div>
        <h2 className="text-2xl font-semibold mb-2 text-center">Connexion</h2>
        <p className="text-sm text-gray-600 mb-6 text-center">Connectez-vous à votre compte</p>

        {status && (
          <div className="mb-4 text-sm font-medium text-green-600">
            {status}
          </div>
        )}

        <form onSubmit={submit} className="space-y-4">
          <div>
            <label htmlFor="email" className="text-sm text-gray-700 flex items-center gap-2">
              <EnvelopeIcon className="w-4 h-4" />
              Email
            </label>
            <div className="relative mt-1">
              <input
                id="email"
                type="email"
                name="email"
                value={data.email}
                className="block w-full border rounded p-2 pl-10 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                autoComplete="username"
                onChange={(e) => setData('email', e.target.value)}
                required
              />
              <EnvelopeIcon className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
            </div>
            {errors.email && <p className="text-sm text-red-600 mt-1">{errors.email}</p>}
          </div>

          <div>
            <label htmlFor="password" className="text-sm text-gray-700 flex items-center gap-2">
              <LockClosedIcon className="w-4 h-4" />
              Mot de passe
            </label>
            <div className="relative mt-1">
              <input
                id="password"
                type="password"
                name="password"
                value={data.password}
                className="block w-full border rounded p-2 pl-10 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                autoComplete="current-password"
                onChange={(e) => setData('password', e.target.value)}
                required
              />
              <LockClosedIcon className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
            </div>
            {errors.password && <p className="text-sm text-red-600 mt-1">{errors.password}</p>}
          </div>

          <div className="flex items-center justify-between">
            <label className="flex items-center gap-2 text-sm text-gray-600">
              <input
                type="checkbox"
                checked={data.remember}
                onChange={(e) => setData('remember', e.target.checked)}
                className="h-4 w-4"
              />
              Se souvenir de moi
            </label>

            {canResetPassword && (
              <Link
                href={route('password.request')}
                className="text-sm text-blue-600 hover:underline"
              >
                Mot de passe oublié ?
              </Link>
            )}
          </div>

          <button
            type="submit"
            className="w-full bg-blue-600 text-white rounded py-2 hover:bg-blue-700 disabled:opacity-50 transition-colors flex items-center justify-center gap-2"
            disabled={processing}
          >
            <ArrowRightOnRectangleIcon className="w-5 h-5" />
            Se connecter
          </button>

          <div className="text-sm text-center text-gray-600">
            Pas encore de compte ?{' '}
            <Link href={route('register')} className="text-blue-600 hover:underline">
              S'inscrire
            </Link>
          </div>
        </form>
      </div>
    </div>
  );
}
