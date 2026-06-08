<?php

namespace Database\Seeders;

use App\Models\Event;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;

class EventSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::query()->where('email', 'admin@example.com')->first();
        if (! $admin) {
            $this->call(AdminUserSeeder::class);
            $admin = User::query()->where('email', 'admin@example.com')->first();
        }

        if (! $admin) {
            return;
        }

        Storage::disk('public')->makeDirectory('events');

        $events = [
            [
                'title' => 'Festival de Musique Électronique',
                'date' => now()->addDays(14)->setTime(20, 0),
                'location' => 'Paris, La Villette',
                'description' => 'Une soirée immersive avec DJs internationaux, lumières et scène outdoor.',
                'asset' => 'concert.jpg',
            ],
            [
                'title' => 'Conférence Tech & Innovation',
                'date' => now()->addDays(21)->setTime(9, 30),
                'location' => 'Lyon, Centre de Congrès',
                'description' => 'Talks sur le cloud, DevOps et l\'IA appliquée aux applications métier.',
                'asset' => 'conference.jpg',
            ],
            [
                'title' => 'Atelier Laravel & React',
                'date' => now()->addDays(7)->setTime(14, 0),
                'location' => 'Marseille, Campus Numérique',
                'description' => 'Workshop pratique : API Laravel, Inertia.js et déploiement Docker.',
                'asset' => 'workshop.jpg',
            ],
            [
                'title' => 'Festival Gastronomique',
                'date' => now()->addDays(30)->setTime(11, 0),
                'location' => 'Bordeaux, Quais de la Garonne',
                'description' => 'Dégustations, food trucks et chefs locaux sur les bords de l\'eau.',
                'asset' => 'festival.jpg',
            ],
        ];

        foreach ($events as $data) {
            $assetFile = database_path('seeders/assets/events/'.$data['asset']);
            $storagePath = 'events/'.$data['asset'];

            if (File::isFile($assetFile) && ! Storage::disk('public')->exists($storagePath)) {
                Storage::disk('public')->put($storagePath, File::get($assetFile));
            }

            Event::updateOrCreate(
                ['title' => $data['title']],
                [
                    'creator_id' => $admin->id,
                    'date' => $data['date'],
                    'location' => $data['location'],
                    'description' => $data['description'],
                    'image_path' => Storage::disk('public')->exists($storagePath) ? $storagePath : null,
                ]
            );
        }
    }
}
