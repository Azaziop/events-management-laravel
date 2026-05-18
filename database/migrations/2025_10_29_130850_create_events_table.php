<?php
// database/migrations/2025_10_29_100000_create_events_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
  public function up(): void {
    Schema::create('events', function (Blueprint $table) {
      $table->id();
      $table->foreignId('creator_id')->constrained('users')->cascadeOnDelete();
      $table->string('title', 200);
      $table->dateTime('date');
      $table->string('location', 255);
      $table->text('description')->nullable();
      $table->string('image_path')->nullable();
      $table->timestamps();
    });
  }
  public function down(): void {
    Schema::dropIfExists('events');
  }
};
