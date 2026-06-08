<?php

use App\Models\User;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@example.com'],
            ['name' => 'Admin', 'password' => 'secret', 'role' => 'admin']
        );
    }

    public function down(): void
    {
        User::where('email', 'admin@example.com')->delete();
    }
};
