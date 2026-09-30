class_name Explosion
extends Node2D

const SPOKES := 8
const INNER_RADIUS_RATIO := 0.4

@onready var _sprite: Sprite2D = $Visual
var _color := Color.WHITE
var _radius := 8.0
var _duration := 0.4
var _elapsed := 0.0


func setup(sprite_name: String, color: Color, radius: float, duration: float) -> void:
	_color = color
	_radius = radius
	_duration = duration
	var texture := AssetLibrary.load_texture(sprite_name)
	if texture != null:
		_sprite = $Visual
		_sprite.texture = texture
		_sprite.hframes = AssetLibrary.frame_count(texture)
		_sprite.scale = Vector2.ONE * (2.0 if radius > 10.0 else 1.0)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		queue_free()
		return
	if _sprite != null:
		_sprite.frame = mini(floori(_progress() * _sprite.hframes), _sprite.hframes - 1)
	else:
		queue_redraw()


func _progress() -> float:
	return _elapsed / _duration


func _draw() -> void:
	if _sprite != null:
		return
	var outer := _radius * _progress()
	var color := _color.lerp(Color.WHITE, _progress())
	for spoke in SPOKES:
		var direction := Vector2.RIGHT.rotated(TAU * spoke / SPOKES)
		draw_line(direction * outer * INNER_RADIUS_RATIO, direction * outer, color)
