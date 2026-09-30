class_name Player
extends Area2D

const BODY_SIZE := Vector2(13.0, 12.0)
const BODY_COLOR := Color("e8e8ff")
const EDGE_MARGIN := 9.0
const TOUCH_DEADZONE := 2.0
const MISSILE_OFFSET := Vector2(0.0, -9.0)

var controllable := false:
	set(value):
		controllable = value
		if has_node("CollisionShape2D"):
			$CollisionShape2D.set_deferred("disabled", not value)
var missile_loaded := true:
	set(value):
		missile_loaded = value
		queue_redraw()

var _touch_index := -1
var _touch_x := 0.0


func _ready() -> void:
	$Visual.setup("player", BODY_COLOR, BODY_SIZE, ArcadeSprite.Shape.WEDGE_UP)


func reset_to_start() -> void:
	position = Vector2(GameRules.SCREEN_SIZE.x / 2.0, GameRules.PLAYER_Y)
	missile_loaded = true
	controllable = false
	visible = true
	_touch_index = -1


func missile_spawn_point() -> Vector2:
	return position + MISSILE_OFFSET


func hit_rect() -> Rect2:
	var shape: RectangleShape2D = $CollisionShape2D.shape
	return Rect2(position + $CollisionShape2D.position - shape.size / 2.0, shape.size)


func wants_to_fire() -> bool:
	return controllable and missile_loaded and (Input.is_action_pressed("fire") or _touch_index >= 0)


func _process(delta: float) -> void:
	if not controllable:
		return
	var travel := _move_direction() * GameRules.PLAYER_SPEED * delta
	position.x = clampf(position.x + travel, EDGE_MARGIN, GameRules.SCREEN_SIZE.x - EDGE_MARGIN)


func _move_direction() -> float:
	if _touch_index < 0:
		return Input.get_axis("move_left", "move_right")
	var offset := _touch_x - position.x
	return 0.0 if absf(offset) < TOUCH_DEADZONE else signf(offset)


func _unhandled_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null:
		_on_touch(touch)
		return
	var drag := event as InputEventScreenDrag
	if drag != null and drag.index == _touch_index:
		_touch_x = drag.position.x


func _on_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed and _touch_index < 0 and controllable:
		_touch_index = touch.index
		_touch_x = touch.position.x
	elif not touch.pressed and touch.index == _touch_index:
		_touch_index = -1
