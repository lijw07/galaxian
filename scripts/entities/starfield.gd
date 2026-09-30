class_name Starfield
extends Node2D

const STAR_COUNT := 72
const SCROLL_SPEED := 16.0
const TWINKLE_SPEED := 3.0
const VISIBLE_THRESHOLD := -0.3
const PALETTE: Array[Color] = [
	Color("ff5050"), Color("50ff50"), Color("5080ff"), Color("ffff50"),
	Color("ff50ff"), Color("50ffff"), Color("ffffff"),
]

var scrolling := true

var _positions := PackedVector2Array()
var _colors := PackedColorArray()
var _phases := PackedFloat32Array()
var _time := 0.0


func _ready() -> void:
	for _index in STAR_COUNT:
		_positions.append(Vector2(randf() * GameRules.SCREEN_SIZE.x, randf() * GameRules.SCREEN_SIZE.y))
		_colors.append(PALETTE.pick_random())
		_phases.append(randf() * TAU)


func _process(delta: float) -> void:
	_time += delta
	if scrolling:
		_scroll(delta)
	queue_redraw()


func _scroll(delta: float) -> void:
	for index in _positions.size():
		var star := _positions[index]
		star.y = fmod(star.y + SCROLL_SPEED * delta, GameRules.SCREEN_SIZE.y)
		_positions[index] = star


func _draw() -> void:
	for index in _positions.size():
		if sin(_time * TWINKLE_SPEED + _phases[index]) > VISIBLE_THRESHOLD:
			draw_rect(Rect2(_positions[index].floor(), Vector2.ONE), _colors[index])
