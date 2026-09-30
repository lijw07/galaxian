class_name ArcadeText
extends RefCounted

const GLYPHS = preload("res://assets/ui/glyphs.png")


static func width(text: String, pixel_scale: int = 1) -> float:
	return maxi(0, text.length() * 6 - 1) * pixel_scale


static func draw_left(canvas: CanvasItem, text: String, origin: Vector2, color: Color, pixel_scale: int = 1) -> void:
	for index in text.length():
		var code := text.to_upper().unicode_at(index) - 32
		if code < 0 or code >= 96:
			continue
		var source := Rect2(Vector2(code % 16 * 6, floori(code / 16.0) * 8), Vector2(5, 7))
		var target := Rect2((origin + Vector2(index * 6 * pixel_scale, -7 * pixel_scale)).round(), Vector2(5, 7) * pixel_scale)
		canvas.draw_texture_rect_region(GLYPHS, target, source, color)


static func draw_centered(canvas: CanvasItem, text: String, center_x: float, baseline_y: float, color: Color, pixel_scale: int = 1) -> void:
	draw_left(canvas, text, Vector2(roundf(center_x - width(text, pixel_scale) / 2.0), baseline_y), color, pixel_scale)


static func draw_right(canvas: CanvasItem, text: String, right_x: float, baseline_y: float, color: Color) -> void:
	draw_left(canvas, text, Vector2(roundf(right_x - width(text)), baseline_y), color)
