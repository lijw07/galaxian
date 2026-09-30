extends Node2D

@onready var _title: TitleScreen = $TitleScreen
@onready var _game: Game = $Game
@onready var _hud: Hud = $Hud
@onready var _pause: ArcadeMenu = $PauseMenu
@onready var _game_over_menu: ArcadeMenu = $GameOverMenu
@onready var _high_scores: ArcadeMenu = $HighScores
@onready var _music: Node = get_node("/root/Music")


func _ready() -> void:
	_hud.high_score = HighScoreStore.load_high_score()
	_title.start_requested.connect(_on_start_requested)
	_title.selected.connect(_on_menu_action)
	_pause.selected.connect(_on_menu_action)
	_game_over_menu.selected.connect(_on_menu_action)
	_high_scores.selected.connect(_on_menu_action)
	_game.game_over.connect(_on_game_over)
	_show_title()


func _on_start_requested() -> void:
	_close_menus()
	_hud.show()
	_game.start_new_game()
	_music.play("gameplay")


func _on_game_over(final_score: int) -> void:
	HighScoreStore.save_high_score(_hud.high_score)
	_hud.hide()
	_game_over_menu.score = final_score
	_game_over_menu.open()
	_music.play("game_over")


func _show_title() -> void:
	_close_menus()
	_game.stop()
	_hud.show_attract()
	_hud.hide()
	_title.open()
	_music.play("title")


func _close_menus() -> void:
	get_tree().paused = false
	_music.set_paused(false)
	for menu: ArcadeMenu in [_title, _pause, _game_over_menu, _high_scores]:
		menu.close()


func _on_menu_action(action: String) -> void:
	match action:
		"resume":
			_pause.close()
			get_tree().paused = false
			_music.set_paused(false)
		"restart":
			_on_start_requested()
		"menu":
			_show_title()
		"scores":
			_title.close()
			_high_scores.score = _hud.high_score
			_high_scores.open()
		"quit":
			get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _pause.visible:
		_on_menu_action("resume")
	elif _game.visible:
		get_tree().paused = true
		_music.set_paused(true)
		_pause.open()
	elif _high_scores.visible or _game_over_menu.visible:
		_show_title()
	get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if is_instance_valid(_music):
		_music.stop()
	var effects := get_node_or_null("/root/Sfx")
	if effects != null:
		effects.stop_all()
