<?php

namespace App\Providers;

use Illuminate\Support\Facades\Vite;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Gate;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Définir le Gate admin-only
        Gate::define('admin-only', function ($user) {
            return $user->role === 'admin';
        });

        // Planifier la notification des événements terminés
        if ($this->app->runningInConsole()) {
            $this->app->afterResolving(\Illuminate\Console\Scheduling\Schedule::class, function ($schedule) {
                $schedule->command('events:notify-ended')->everyTenMinutes();
            });
        }
    }

}
