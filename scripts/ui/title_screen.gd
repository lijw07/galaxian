class_name TitleScreen
extends ArcadeMenu

signal start_requested

const QUIT_ACTION := "quit"


func _ready() -> void:
	if OS.has_feature("web"):
		_remove_action(QUIT_ACTION)
	super._ready()
	selected.connect(func(action: String) -> void:
		if action == "start":
			start_requested.emit()
	)


func _process(delta: float) -> void:
	super._process(delta)
	$BossIcon.show_frame([0, 1, 2, 1][floori(_input_time / 0.2) % 4])


func _remove_action(action: String) -> void:
	var index := actions.find(action)
	if index < 0:
		return
	actions.remove_at(index)
	options.remove_at(index)
