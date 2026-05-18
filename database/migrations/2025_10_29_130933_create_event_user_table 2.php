<?php
// database/migrations/2025_10_29_100100_create_event_user_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
  public function up(): void {
    Schema::create('event_user', function (Blueprint $table) {
      $table->id();
      $table->foreignId('event_id')->constrained('events')->cascadeOnDelete();
      $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
      $table->timestamps();
      $table->unique(['event_id','user_id']);
    });
  }
  public function down(): void {
    Schema::dropIfExists('event_user');
  }
};
