extends Node2D

const EXPLOSION = preload("res://scenes/effects/explosion.tscn")
var _clock := 0.0


func _ready() -> void:
	for child in get_children():
		if child is Alien:
			child.reveal()
		elif child is Player or child is Projectile:
			child.set_process(false)


func _process(delta: float) -> void:
	_clock += delta
	if _clock >= 0.8:
		_clock = 0.0
		var effect := EXPLOSION.instantiate() as Explosion
		effect.position = Vector2(165, 204)
		add_child(effect)
	queue_redraw()


func _draw() -> void:
	ArcadeText.draw_centered(self, "ASSET GALLERY", 112, 17, Color.YELLOW)
	var labels := ["PLAYER", "GREEN", "VIOLET", "RED", "BOSS", "SHOTS", "EXPLOSION"]
	var positions := [Vector2(40, 79), Vector2(112, 79), Vector2(184, 79), Vector2(65, 149), Vector2(159, 149), Vector2(60, 237), Vector2(166, 237)]
	for index in labels.size():
		ArcadeText.draw_centered(self, labels[index], positions[index].x, positions[index].y, Color.WHITE)
	for child in get_children():
		if child is Area2D:
			var shape: CollisionShape2D = child.get_node("CollisionShape2D")
			var size: Vector2 = shape.shape.size * child.scale
			draw_rect(Rect2(child.position + shape.position - size / 2.0, size), Color(0.2, 1, 0.5, 0.7), false, 1)
