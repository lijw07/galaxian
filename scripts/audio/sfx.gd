extends Node

const VOICE_COUNT := 8
const EFFECT_VOLUME_DB := -14.0
const AMBIENCE_VOLUME_DB := -30.0

var _streams: Dictionary[String, AudioStream] = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _ambience: AudioStreamPlayer


func _ready() -> void:
	_build_streams()
	_build_voices()
	_build_ambience()


func play(sound_name: String) -> void:
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = _streams[sound_name]
	voice.play()


func start_ambience() -> void:
	if not _ambience.playing:
		_ambience.play()


func stop_ambience() -> void:
	_ambience.stop()


func stop_all() -> void:
	stop_ambience()
	for voice in _voices:
		voice.stop()
		voice.stream = null


func _build_streams() -> void:
	_streams["shoot"] = SoundSynth.sweep(1500.0, 420.0, 0.14, true)
	_streams["alien_hit"] = SoundSynth.noise(0.25, 0.45)
	_streams["flagship_hit"] = SoundSynth.noise(0.5, 0.25)
	_streams["player_hit"] = SoundSynth.noise(1.3, 0.1)
	_streams["dive"] = SoundSynth.sweep(1300.0, 350.0, 0.9, false)
	_streams["extra_life"] = SoundSynth.melody(PackedFloat32Array([784.0, 988.0, 1175.0, 1568.0]), 0.08)
	_streams["start"] = SoundSynth.melody(PackedFloat32Array([392.0, 523.0, 659.0, 784.0, 659.0, 784.0, 1047.0]), 0.13)


func _build_voices() -> void:
	for _index in VOICE_COUNT:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = EFFECT_VOLUME_DB
		add_child(voice)
		_voices.append(voice)


func _build_ambience() -> void:
	_ambience = AudioStreamPlayer.new()
	_ambience.stream = SoundSynth.drone(170.0, 45.0, 2.0)
	_ambience.volume_db = AMBIENCE_VOLUME_DB
	add_child(_ambience)
