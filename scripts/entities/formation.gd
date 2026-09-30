class_name Formation
extends Node

const COLUMNS := 10
const COLUMN_SPACING := 18.0
const ROW_SPACING := 16.0
const TOP_Y := 44.0
const SWAY_RANGE := 18.0
const SWAY_SPEED := 12.0
const FLAGSHIP_ROW := 0
const RED_ROW := 1
const PURPLE_ROW := 2
const BLUE_ROWS := [3, 4, 5]
const FLAGSHIP_COLUMNS: Array[int] = [3, 6, 4, 5]
const RED_COLUMNS := [2, 3, 4, 5, 6, 7]
const PURPLE_COLUMNS := [1, 2, 3, 4, 5, 6, 7, 8]

var _offset := 0.0
var _direction := 1.0


static func layout(flagship_count: int) -> Dictionary[Vector2i, GameRules.Kind]:
	var slots: Dictionary[Vector2i, GameRules.Kind] = {}
	for column in FLAGSHIP_COLUMNS.slice(0, flagship_count):
		slots[Vector2i(column, FLAGSHIP_ROW)] = GameRules.Kind.FLAGSHIP
	for column: int in RED_COLUMNS:
		slots[Vector2i(column, RED_ROW)] = GameRules.Kind.RED
	for column: int in PURPLE_COLUMNS:
		slots[Vector2i(column, PURPLE_ROW)] = GameRules.Kind.PURPLE
	for row: int in BLUE_ROWS:
		for column in COLUMNS:
			slots[Vector2i(column, row)] = GameRules.Kind.BLUE
	return slots


func reset() -> void:
	_offset = 0.0
	_direction = 1.0


func slot_position(slot: Vector2i) -> Vector2:
	var center_x := GameRules.SCREEN_SIZE.x / 2.0 + _offset
	var column_offset := (slot.x - (COLUMNS - 1) / 2.0) * COLUMN_SPACING
	return Vector2(roundf(center_x + column_offset), TOP_Y + slot.y * ROW_SPACING)


func _process(delta: float) -> void:
	_offset += _direction * SWAY_SPEED * delta
	if absf(_offset) >= SWAY_RANGE:
		_offset = clampf(_offset, -SWAY_RANGE, SWAY_RANGE)
		_direction = -_direction
