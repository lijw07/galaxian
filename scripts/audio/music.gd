extends Node

const TRACKS := {
	"title": preload("res://assets/music/star-formation-title.wav"),
	"gameplay": preload("res://assets/music/dive-attack-gameplay.wav"),
	"game_over": preload("res://assets/music/last-flight-game-over.wav"),
}
var current_track := ""
var _player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.volume_db = -9.0
	add_child(_player)


func play(track: String) -> void:
	if current_track == track and _player.playing:
		_player.stream_paused = false
		return
	current_track = track
	var stream := TRACKS[track].duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED if track == "game_over" else AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	_player.stream = stream
	_player.stream_paused = false
	_player.play()


func set_paused(paused: bool) -> void:
	_player.stream_paused = paused


func stop() -> void:
	_player.stop()
	_player.stream = null
	current_track = ""
