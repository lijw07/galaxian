class_name HighScoreStore
extends RefCounted

const SAVE_PATH := "user://galaxian.cfg"
const SECTION := "scores"
const KEY := "high_score"
static var save_path := SAVE_PATH


static func load_high_score() -> int:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return 0
	return int(config.get_value(SECTION, KEY, 0))


static func save_high_score(score: int) -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, KEY, score)
	config.save(save_path)
