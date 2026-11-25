class_name KitSound
extends Node
## Sound effects (a few players, so quick effects overlap; a new effect takes a free player, or the
## one whose sound ends first, so a long fanfare isn't cut by quick effects) and one looping music
## track, each with its own on/off switch. The game saves the switches.

signal played(name: StringName)

const EFFECT_PLAYERS := 4

var effects_on := true
## Seconds, for choosing a free player (tests replace it).
var clock: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0
var music_on := false:
	set(value):
		music_on = value
		_update_music()

var _effects := {}
var _players: Array[AudioStreamPlayer] = []
## When each player's current sound ends, in clock seconds.
var _ends: Array[float] = []
var _music: AudioStreamPlayer
var _music_started := false


func _init() -> void:
	for i in EFFECT_PLAYERS:
		var player := AudioStreamPlayer.new()
		_players.append(player)
		_ends.append(0.0)
		add_child(player)
	_music = AudioStreamPlayer.new()
	add_child(_music)


func add_effect(effect: StringName, stream: AudioStream) -> void:
	_effects[effect] = stream


func play(effect: StringName) -> void:
	if not effects_on or not _effects.has(effect):
		return
	var now: float = clock.call()
	var pick := 0
	for i in EFFECT_PLAYERS:
		if _ends[i] < _ends[pick]:
			pick = i
	var player := _players[pick]
	var stream: AudioStream = _effects[effect]
	_ends[pick] = now + stream.get_length()
	player.stream = stream
	if player.is_inside_tree():
		player.play()
	played.emit(effect)


## The music loops; it starts now if music is on.
func set_music(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream != null and "loop" in stream:
		stream.set("loop", true)
	_music.stream = stream
	_music_started = false
	_update_music()


func is_music_playing() -> bool:
	return _music_started


func _update_music() -> void:
	var should := music_on and _music.stream != null
	if should and not _music_started:
		_music_started = true
		if _music.is_inside_tree():
			_music.play()
	elif not should and _music_started:
		_music_started = false
		_music.stop()


func _ready() -> void:
	if _music_started and not _music.playing:
		_music.play()
