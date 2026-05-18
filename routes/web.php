<?php

use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

use App\Http\Controllers\ProfileController;
use App\Http\Controllers\EventController;
use App\Http\Controllers\ParticipantController;
use App\Http\Controllers\Admin\UserController as AdminUserController;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
*/

// Accueil public (landing) — affiche les événements récents en lecture seule
Route::get('/', [EventController::class, 'home'])->name('home');

// Dashboard (protégé) — via contrôleur pour charger les données nécessaires

// Profil (protégé)
Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

// Événements + participation (protégés)
Route::middleware(['auth', 'verified'])->group(function () {
    // CRUD événements
    Route::resource('events', EventController::class);

    // Participation aux événements
    Route::post('events/{event}/join', [ParticipantController::class, 'store'])->name('events.join');
    Route::get('events/{event}/auto-join', [ParticipantController::class, 'autoJoin'])->name('events.auto-join');
    Route::delete('events/{event}/leave', [ParticipantController::class, 'destroy'])->name('events.leave');
});

// Zone Admin (protégée par Gate/Policy)
Route::middleware(['auth', 'can:admin-only'])
    ->prefix('admin')
    ->name('admin.')
    ->group(function () {
        Route::get('/users', [AdminUserController::class, 'index'])->name('users.index');
        Route::get('/users/create', [AdminUserController::class, 'create'])->name('users.create');
        Route::post('/users', [AdminUserController::class, 'store'])->name('users.store');
        Route::get('/users/{user}/edit', [AdminUserController::class, 'edit'])->name('users.edit');
        Route::put('/users/{user}', [AdminUserController::class, 'update'])->name('users.update');
        Route::delete('/users/{user}', [AdminUserController::class, 'destroy'])->name('users.destroy');
    });
Route::get('/dashboard', [EventController::class, 'dashboard'])
    ->middleware(['auth', 'verified'])
    ->name('dashboard');

    // routes/web.php
Route::post('/dashboard/events', [EventController::class, 'storeFromDashboard'])
  ->middleware(['auth','verified'])
  ->name('dashboard.events.store');


// Auth scaffolding (Breeze/Fortify)
require __DIR__ . '/auth.php';
