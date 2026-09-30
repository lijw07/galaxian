class_name Hud
extends Node2D

const LABEL_COLOR := Color("ff4040")
const VALUE_COLOR := Color("ffffff")
const LABEL_BASELINE := 8.0
const VALUE_BASELINE := 17.0
const PLAYER_LABEL_X := 16.0
const MESSAGE_BASELINE := 150.0
const BOTTOM_ROW_Y := 248.0
const SHIP_ICON_SPACING := 14.0
const SHIP_ICON_SIZE := Vector2(10.0, 9.0)
const SHIP_ICON_COLOR := Color("e8e8ff")
const MAX_SHIP_ICONS := 4
const FLAG_SPACING := 8.0
const MAX_FLAGS := 3
const FLAG_POLE_COLOR := Color("c0c0c0")
const FLAG_CLOTH_COLOR := Color("ff3030")

var score := 0:
	set(value):
		score = value
		queue_redraw()
var high_score := 0:
	set(value):
		high_score = value
		queue_redraw()
var reserve_ships := 0:
	set(value):
		reserve_ships = value
		queue_redraw()
var round_number := 0:
	set(value):
		round_number = value
		queue_redraw()
var message := "":
	set(value):
		message = value
		queue_redraw()
var message_color := Color("40c8ff")


func show_attract() -> void:
	reserve_ships = 0
	round_number = 0
	message = ""


func _draw() -> void:
	_draw_scores()
	_draw_reserve_ships()
	_draw_flags()
	if not message.is_empty():
		ArcadeText.draw_centered(self, message, GameRules.SCREEN_SIZE.x / 2.0, MESSAGE_BASELINE, message_color)


func _draw_scores() -> void:
	ArcadeText.draw_left(self, "SCORE", Vector2(PLAYER_LABEL_X, LABEL_BASELINE), LABEL_COLOR)
	ArcadeText.draw_left(self, "%06d" % score, Vector2(PLAYER_LABEL_X, VALUE_BASELINE), VALUE_COLOR)
	ArcadeText.draw_centered(self, "HIGH SCORE", 151, LABEL_BASELINE, Color.WHITE)
	ArcadeText.draw_centered(self, "%06d" % high_score, 151, VALUE_BASELINE, Color.RED)


func _draw_reserve_ships() -> void:
	var texture := AssetLibrary.load_texture("player")
	for index in mini(reserve_ships, MAX_SHIP_ICONS):
		var center := Vector2(10.0 + index * SHIP_ICON_SPACING, BOTTOM_ROW_Y)
		if texture != null:
			var size := AssetLibrary.frame_size(texture)
			draw_texture_rect_region(texture, Rect2((center - size / 4.0).round(), size / 2.0), Rect2(Vector2.ZERO, size))
		else:
			_draw_ship_placeholder(center)


func _draw_flags() -> void:
	if round_number > 0:
		ArcadeText.draw_centered(self, "STAGE %02d" % round_number, 127, 253, Color.YELLOW)
	var texture := AssetLibrary.load_texture("flag")
	for index in mini(round_number, MAX_FLAGS):
		var center := Vector2(GameRules.SCREEN_SIZE.x - 6.0 - index * FLAG_SPACING, BOTTOM_ROW_Y)
		if texture != null:
			_draw_first_frame(texture, center)
		else:
			_draw_flag_placeholder(center)


func _draw_first_frame(texture: Texture2D, center: Vector2) -> void:
	var size := AssetLibrary.frame_size(texture)
	draw_texture_rect_region(texture, Rect2((center - size / 2.0).round(), size), Rect2(Vector2.ZERO, size))


func _draw_ship_placeholder(center: Vector2) -> void:
	var half := SHIP_ICON_SIZE / 2.0
	var points := PackedVector2Array([
		center + Vector2(0.0, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])
	draw_colored_polygon(points, SHIP_ICON_COLOR)


func _draw_flag_placeholder(center: Vector2) -> void:
	var pole_top := center + Vector2(-2.0, -5.0)
	draw_line(pole_top, center + Vector2(-2.0, 5.0), FLAG_POLE_COLOR)
	var cloth := PackedVector2Array([pole_top, pole_top + Vector2(5.0, 2.0), pole_top + Vector2(0.0, 4.0)])
	draw_colored_polygon(cloth, FLAG_CLOTH_COLOR)
