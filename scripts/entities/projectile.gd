class_name Projectile
extends Area2D

@export var velocity := Vector2.ZERO

var _previous_position := Vector2.ZERO


func setup(start: Vector2, initial_velocity: Vector2, size: Vector2) -> void:
	position = start
	_previous_position = start
	velocity = initial_velocity
	var shape: RectangleShape2D = $CollisionShape2D.shape
	shape.size = size


func _process(delta: float) -> void:
	_previous_position = position
	position += velocity * delta


func swept_rect() -> Rect2:
	var size: Vector2 = $CollisionShape2D.shape.size
	var half := size / 2.0
	var offset: Vector2 = $CollisionShape2D.position
	return Rect2(position + offset - half, size).merge(Rect2(_previous_position + offset - half, size))


func is_off_screen() -> bool:
	return not Rect2(Vector2.ZERO, GameRules.SCREEN_SIZE).has_point(position)
