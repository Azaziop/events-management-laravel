import ProfileLayout from '@/Layouts/ProfileLayout';
import { Head } from '@inertiajs/react';
import DeleteUserForm from './Partials/DeleteUserForm';
import UpdatePasswordForm from './Partials/UpdatePasswordForm';
import UpdateProfileInformationForm from './Partials/UpdateProfileInformationForm';

export default function Edit({ mustVerifyEmail, status }) {
    return (
        <ProfileLayout
            header={
                <h2 className="text-xl font-semibold leading-tight text-gray-800">
                    Mon Profil
                </h2>
            }
        >
            <Head title="Profile" />

            <div className="py-12">
                <div className="mx-auto max-w-3xl space-y-6 sm:px-6 lg:px-8">
                    <div className="bg-white p-6 shadow-sm rounded-lg">
                        <h3 className="text-lg font-medium text-gray-900 mb-6">Informations du profil</h3>
                        <UpdateProfileInformationForm
                            mustVerifyEmail={mustVerifyEmail}
                            status={status}
                            className="max-w-xl"
                        />
                    </div>

                    <div className="bg-white p-6 shadow-sm rounded-lg">
                        <h3 className="text-lg font-medium text-gray-900 mb-6">Modifier le mot de passe</h3>
                        <UpdatePasswordForm className="max-w-xl" />
                    </div>

                    <div className="bg-white p-6 shadow-sm rounded-lg border border-red-100">
                        <h3 className="text-lg font-medium text-gray-900 mb-6">Supprimer le compte</h3>
                        <DeleteUserForm className="max-w-xl" />
                    </div>
                </div>
            </div>
        </ProfileLayout>
    );
}
