class_name ArcadeSprite
extends Sprite2D

enum Shape { BLOCK, WEDGE_UP, WEDGE_DOWN }

const PLACEHOLDER_FLAP_SQUEEZE := 0.2

var _color := Color.WHITE
var _size := Vector2(8.0, 8.0)
var _shape := Shape.BLOCK
var _frame := 0


func setup(sprite_name: String, color: Color, size: Vector2, shape: Shape) -> void:
	_color = color
	_size = size
	_shape = shape
	texture = AssetLibrary.load_texture(sprite_name)
	if texture != null:
		hframes = AssetLibrary.frame_count(texture)
	queue_redraw()


func show_frame(index: int) -> void:
	if index == _frame:
		return
	_frame = index
	if texture != null:
		frame = index % hframes
	else:
		queue_redraw()


func _draw() -> void:
	if texture != null:
		return
	var squeeze := 1.0 - PLACEHOLDER_FLAP_SQUEEZE * float(_frame % 3)
	var half := Vector2(_size.x * squeeze, _size.y) / 2.0
	match _shape:
		Shape.WEDGE_UP:
			draw_colored_polygon(PackedVector2Array([Vector2(0.0, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]), _color)
		Shape.WEDGE_DOWN:
			draw_colored_polygon(PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(0.0, half.y)]), _color)
		_:
			draw_rect(Rect2(-half, half * 2.0), _color)
