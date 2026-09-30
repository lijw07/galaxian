class_name ScorePopup
extends Node2D

const LIFETIME := 1.2
const BASELINE_OFFSET := 4.0

var _text := ""
var _color := Color.WHITE
var _age := 0.0


func setup(text: String, color: Color) -> void:
	_text = text
	_color = color
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()


func _draw() -> void:
	ArcadeText.draw_centered(self, _text, 0.0, BASELINE_OFFSET, _color)
