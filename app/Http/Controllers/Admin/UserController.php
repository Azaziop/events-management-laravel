<?php

// app/Http/Controllers/Admin/UserController.php
namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $users = User::query()
            ->when($request->input('search'), function ($q, $s) {
                $q->where(fn($qq)=>$qq->where('name','ilike',"%$s%")->orWhere('email','ilike',"%$s%"));
            })
            ->latest()
            ->paginate(10)
            ->withQueryString();

        return Inertia::render('Admin/Users/Index', [
            'users' => $users,
            'filters' => ['search' => $request->input('search')],
        ]);
    }

    public function create()
    {
        return Inertia::render('Admin/Users/Create');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required','max:255','regex:/^[a-zA-ZÀ-ÿ\s\-\']+$/u'],
            'email' => ['required','email','max:255','unique:users,email'],
            'password' => ['required','min:8','confirmed'],
            'role' => ['required', Rule::in(['user','admin'])],
        ], [
            'name.regex' => 'Le nom ne doit contenir que des lettres, espaces, tirets et apostrophes.',
        ]);
        $data['password'] = bcrypt($data['password']);
        User::create($data);
        return to_route('admin.users.index');
    }

    public function edit(User $user)
    {
        return Inertia::render('Admin/Users/Edit', ['user' => $user]);
    }

    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'name' => ['required','max:255','regex:/^[a-zA-ZÀ-ÿ\s\-\']+$/u'],
            'email' => ['required','email','max:255', Rule::unique('users','email')->ignore($user->id)],
            'password' => ['nullable','min:8','confirmed'],
            'role' => ['required', Rule::in(['user','admin'])],
        ], [
            'name.regex' => 'Le nom ne doit contenir que des lettres, espaces, tirets et apostrophes.',
        ]);
        if (empty($data['password'])) unset($data['password']); else $data['password'] = bcrypt($data['password']);
        $user->update($data);
        return to_route('admin.users.index');
    }

    public function destroy(User $user)
    {
        $user->delete();
        return back();
    }
}
