class_name AssetLibrary
extends RefCounted

const SPRITE_DIRECTORY := "res://assets/sprites/"
const FONT_PATH := "res://assets/fonts/arcade.ttf"

static var _textures: Dictionary[String, Texture2D] = {}
static var _font: Font


static func load_texture(sprite_name: String) -> Texture2D:
	if not _textures.has(sprite_name):
		_textures[sprite_name] = _load_texture_file(SPRITE_DIRECTORY + sprite_name + ".png")
	return _textures[sprite_name]


static func frame_count(texture: Texture2D) -> int:
	return maxi(1, floori(float(texture.get_width()) / texture.get_height()))


static func frame_size(texture: Texture2D) -> Vector2:
	return Vector2(texture.get_height(), texture.get_height())


static func font() -> Font:
	if _font == null:
		_font = load(FONT_PATH) as Font if ResourceLoader.exists(FONT_PATH) else ThemeDB.fallback_font
	return _font


static func _load_texture_file(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
