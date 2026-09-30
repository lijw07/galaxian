class_name TitleScreen
extends ArcadeMenu

signal start_requested


func _ready() -> void:
	super._ready()
	selected.connect(func(action: String) -> void:
		if action == "start":
			start_requested.emit()
	)


func _process(delta: float) -> void:
	super._process(delta)
	$BossIcon.show_frame([0, 1, 2, 1][floori(_input_time / 0.2) % 4])
