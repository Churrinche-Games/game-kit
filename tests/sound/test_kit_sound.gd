extends GutTest


## A silent 16-bit mono WAV of the given length. (data is copied in: Godot returns packed arrays
## by value, so resizing wav.data in place would change a copy.)
func _wav(seconds := 0.1) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(int(22050 * seconds) * 2)
	wav.data = data
	return wav


func _sound() -> KitSound:
	var sound := KitSound.new()
	add_child_autofree(sound)
	sound.add_effect(&"tap", _wav())
	return sound


func test_plays_known_effect() -> void:
	var sound := _sound()
	watch_signals(sound)
	sound.play(&"tap")
	assert_signal_emitted_with_parameters(sound, "played", [&"tap"])


func test_unknown_effect_is_silent() -> void:
	var sound := _sound()
	watch_signals(sound)
	sound.play(&"nope")
	assert_signal_not_emitted(sound, "played")


func test_effects_off_is_silent() -> void:
	var sound := _sound()
	sound.effects_on = false
	watch_signals(sound)
	sound.play(&"tap")
	assert_signal_not_emitted(sound, "played")


func test_music_off_by_default() -> void:
	var sound := _sound()
	sound.set_music(_wav())
	assert_false(sound.music_on)
	assert_false(sound.is_music_playing())


func test_music_toggle_starts_and_stops() -> void:
	var sound := _sound()
	sound.set_music(_wav())
	sound.music_on = true
	assert_true(sound.is_music_playing())
	sound.music_on = false
	assert_false(sound.is_music_playing())


func test_music_on_without_a_stream_is_quiet() -> void:
	var sound := _sound()
	sound.music_on = true
	assert_false(sound.is_music_playing())
	sound.set_music(_wav())
	assert_true(sound.is_music_playing())


func test_five_quick_effects_use_four_players() -> void:
	var sound := _sound()
	watch_signals(sound)
	for i in 5:
		sound.play(&"tap")
	assert_signal_emit_count(sound, "played", 5)
	assert_eq(sound.find_children("*", "AudioStreamPlayer", false, false).size(), 5)


func test_music_set_before_entering_the_tree_starts_when_ready() -> void:
	var sound := KitSound.new()
	sound.music_on = true
	sound.set_music(_wav())
	add_child_autofree(sound)
	assert_true(sound.is_music_playing())
	sound.set_music(null)
	assert_false(sound.is_music_playing())


func test_a_long_effect_is_not_cut_by_quick_ones() -> void:
	var sound := _sound()
	var long := _wav(1.3)
	assert_almost_eq(long.get_length(), 1.3, 0.01)
	sound.add_effect(&"fanfare", long)
	var now := [0.0]
	sound.clock = func() -> float: return now[0]
	sound.play(&"fanfare")
	for i in 4:
		now[0] = 0.1 + i * 0.28
		sound.play(&"tap")
	var players := sound.find_children("*", "AudioStreamPlayer", false, false)
	var holders := players.filter(func(p: AudioStreamPlayer) -> bool: return p.stream == long)
	assert_eq(holders.size(), 1, "the fanfare keeps its player")


func test_when_all_are_busy_the_one_ending_first_is_reused() -> void:
	var sound := _sound()
	var long := _wav(2.0)
	sound.add_effect(&"long", long)
	var now := [0.0]
	sound.clock = func() -> float: return now[0]
	for i in 3:
		sound.play(&"long")
	sound.play(&"tap")  # ends at 0.1 s, before the long ones
	now[0] = 0.05
	sound.play(&"tap")
	var players := sound.find_children("*", "AudioStreamPlayer", false, false)
	assert_eq(players.filter(func(p: AudioStreamPlayer) -> bool: return p.stream == long).size(), 3)
