<?php

// app/Policies/EventPolicy.php
namespace App\Policies;

use App\Models\Event;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class EventPolicy
{
    public function viewAny(User $user): bool { return true; }

    public function view(User $user, Event $event): bool { return true; }

    public function create(User $user): bool
    {
        return in_array($user->role, ['user','admin']);
    }

    public function update(User $user, Event $event): bool
    {
        return $user->id === $event->creator_id || $user->role === 'admin';
    }

    public function delete(User $user, Event $event): bool
    {
        return $user->id === $event->creator_id || $user->role === 'admin';
    }
}
