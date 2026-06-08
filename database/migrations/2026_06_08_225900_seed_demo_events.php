<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Artisan;

return new class extends Migration
{
    public function up(): void
    {
        if (! class_exists(\Database\Seeders\EventSeeder::class)) {
            return;
        }

        Artisan::call('db:seed', [
            '--class' => 'Database\\Seeders\\EventSeeder',
            '--force' => true,
        ]);
    }

    public function down(): void
    {
        // Données de démo — pas de rollback destructif
    }
};
