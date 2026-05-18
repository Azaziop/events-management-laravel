<?php
// app/Models/Event.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Event extends Model
{
  protected $fillable = ['title','date','location','description','image_path','creator_id'];

  protected $appends = ['image_url', 'is_past'];

  public function creator() { return $this->belongsTo(User::class, 'creator_id'); }

  public function participants()
  {
      return $this->belongsToMany(\App\Models\User::class, 'event_user', 'event_id', 'user_id');
  }

  // Accesseur pour générer l'URL complète de l'image
  public function getImageUrlAttribute()
  {
      return $this->image_path
          ? Storage::url($this->image_path)
          : null;
  }

  // Indique si l'événement est déjà passé
  public function getIsPastAttribute(): bool
  {
    $date = is_string($this->date) ? \Carbon\Carbon::parse($this->date) : $this->date;
    if (!$date) return false;
    return $date->isPast();
  }
}
