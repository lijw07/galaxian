class_name ArcadeMenu
extends Node2D

signal selected(action: String)

@export var heading := ""
@export var options := PackedStringArray()
@export var actions := PackedStringArray()
@export var first_baseline := 148.0
@export var heading_y := 92.0
@export var heading_color := Color.YELLOW
@export var dim_background := false
@export var show_score := false

var score := 0
var selected_index := 0
var _input_time := 0.0
const CURSOR = preload("res://assets/ui/cursor.png")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close()


func open() -> void:
	selected_index = 0
	_input_time = 0.0
	show()
	set_process(true)
	set_process_unhandled_input(true)
	queue_redraw()


func close() -> void:
	hide()
	set_process(false)
	set_process_unhandled_input(false)


func _process(delta: float) -> void:
	_input_time += delta


func _unhandled_input(event: InputEvent) -> void:
	if _input_time < 0.2:
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		selected_index = posmod(selected_index + (-1 if event.is_action_pressed("ui_up") else 1), options.size())
		get_viewport().set_input_as_handled()
		queue_redraw()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("fire"):
		_choose(selected_index)
	elif event is InputEventScreenTouch and event.pressed:
		_pick_at(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pick_at(event.position)


func _pick_at(at: Vector2) -> void:
	for index in options.size():
		if Rect2(24, first_baseline + index * 22 - 16, 176, 22).has_point(at):
			_choose(index)
			return


func _choose(index: int) -> void:
	selected_index = index
	get_viewport().set_input_as_handled()
	selected.emit(actions[index])


func _draw() -> void:
	if dim_background:
		draw_rect(Rect2(Vector2.ZERO, GameRules.SCREEN_SIZE), Color(0, 0, 0, 0.9))
	if not heading.is_empty():
		var scale_factor := 2 if heading.length() <= 10 else 1
		ArcadeText.draw_centered(self, heading, 113, heading_y + 1, Color.RED, scale_factor)
		ArcadeText.draw_centered(self, heading, 112, heading_y, heading_color, scale_factor)
	if show_score:
		ArcadeText.draw_centered(self, "SCORE", 112, 114, Color.WHITE)
		ArcadeText.draw_centered(self, "%06d" % score, 112, 130, Color.YELLOW)
	for index in options.size():
		var baseline := first_baseline + index * 22
		ArcadeText.draw_centered(self, options[index], 112, baseline, Color.WHITE)
		if index == selected_index:
			draw_texture(CURSOR, Vector2(roundf(112 - ArcadeText.width(options[index]) / 2) - 15, baseline - 8))
