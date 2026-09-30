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

const CURSOR = preload("res://assets/ui/cursor.png")
const INPUT_DELAY := 0.2
const OPTION_SPACING := 22.0
const OPTION_HIT_LEFT := 24.0
const OPTION_HIT_WIDTH := 176.0
const OPTION_HIT_ABOVE_BASELINE := 16.0

var score := 0
var selected_index := 0
var _input_time := 0.0


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
	var motion := event as InputEventMouseMotion
	if motion != null:
		_hover(motion.position)
		return
	if _input_time < INPUT_DELAY:
		return
	if event.is_action_pressed("menu_up"):
		_move_selection(-1)
	elif event.is_action_pressed("menu_down"):
		_move_selection(1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("fire"):
		_choose(selected_index)
	else:
		_handle_pointer_press(event)


func _move_selection(step: int) -> void:
	selected_index = posmod(selected_index + step, options.size())
	get_viewport().set_input_as_handled()
	queue_redraw()


func _hover(at: Vector2) -> void:
	var index := _option_at(at)
	if index < 0 or index == selected_index:
		return
	selected_index = index
	queue_redraw()


func _handle_pointer_press(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_choose_at(click.position)
		return
	var touch := event as InputEventScreenTouch
	if touch != null and touch.pressed and touch.device != InputEvent.DEVICE_ID_EMULATION:
		_choose_at(touch.position)


func _choose_at(at: Vector2) -> void:
	var index := _option_at(at)
	if index >= 0:
		_choose(index)


func _option_at(at: Vector2) -> int:
	for index in options.size():
		var top := _option_baseline(index) - OPTION_HIT_ABOVE_BASELINE
		if Rect2(OPTION_HIT_LEFT, top, OPTION_HIT_WIDTH, OPTION_SPACING).has_point(at):
			return index
	return -1


func _option_baseline(index: int) -> float:
	return first_baseline + index * OPTION_SPACING


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
		var baseline := _option_baseline(index)
		ArcadeText.draw_centered(self, options[index], 112, baseline, Color.WHITE)
		if index == selected_index:
			draw_texture(CURSOR, Vector2(roundf(112 - ArcadeText.width(options[index]) / 2) - 15, baseline - 8))
