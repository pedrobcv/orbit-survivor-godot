extends Node
## AudioManager

## Manages sound effects and music playback using AudioStreamPlayer2D.
## Loads audio from assets/audio/. Silently skips missing sounds to avoid crashes.

signal audio_played(sound_name: String)

## Base path for audio assets.
const AUDIO_DIR: String = "res://assets/audio/"

var _sfx_volume: float = 1.0
var _music_volume: float = 1.0

var _sfx_player: AudioStreamPlayer2D
var _music_player: AudioStreamPlayer2D

var _current_music: String = ""


func _ready() -> void:
	_sfx_player = AudioStreamPlayer2D.new()
	_sfx_player.name = "SFXPlayer"
	add_child(_sfx_player)

	_music_player = AudioStreamPlayer2D.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)


## Plays a sound effect from assets/audio/sfx/.
## sound_name: Filename without extension (e.g. "explosion" → assets/audio/sfx/explosion.ogg).
func play_sfx(sound_name: String) -> void:
	var path := AUDIO_DIR + "sfx/" + sound_name + ".ogg"
	if not _try_load_and_play(_sfx_player, path):
		# Try .wav fallback
		path = AUDIO_DIR + "sfx/" + sound_name + ".wav"
		if not _try_load_and_play(_sfx_player, path):
			push_warning("AudioManager: SFX not found: ", sound_name)
			return
	audio_played.emit(sound_name)


## Plays/loops a music track from assets/audio/music/.
## track_name: Filename without extension (e.g. "main_theme").
func play_music(track_name: String) -> void:
	if track_name == _current_music and _music_player.playing:
		return

	var path := AUDIO_DIR + "music/" + track_name + ".ogg"
	if not _try_load_and_play(_music_player, path):
		path = AUDIO_DIR + "music/" + track_name + ".wav"
		if not _try_load_and_play(_music_player, path):
			push_warning("AudioManager: Music not found: ", track_name)
			return
	_current_music = track_name
	_music_player.set_stream(_music_player.stream)
	audio_played.emit(track_name)


## Sets the volume for sound effects (0.0 to 1.0).
func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)
	_sfx_player.volume_db = linear_to_db(_sfx_volume)


## Sets the volume for music (0.0 to 1.0).
func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	_music_player.volume_db = linear_to_db(_music_volume)


## Returns the current SFX volume (0.0 – 1.0).
func get_sfx_volume() -> float:
	return _sfx_volume


## Returns the current music volume (0.0 – 1.0).
func get_music_volume() -> float:
	return _music_volume


## Internal: Tries to load an audio file and play it.
## Returns true on success, false if file doesn't exist.
func _try_load_and_play(player: AudioStreamPlayer2D, path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false

	var stream := load(path) as AudioStream
	if stream == null:
		return false

	player.set_stream(stream)
	player.play()
	return true


## Converts a linear volume (0–1) to Godot's dB scale.
func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)
