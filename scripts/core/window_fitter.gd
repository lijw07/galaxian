class_name WindowFitter
extends RefCounted

const SCREEN_FILL := 0.9


static func fit_to_screen(window: Window) -> void:
	if not _has_resizable_window():
		return
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	var size := Vector2i(GameRules.SCREEN_SIZE * _best_scale(Vector2(usable.size) * SCREEN_FILL))
	window.size = size
	window.position = usable.position + (usable.size - size) / 2


static func _has_resizable_window() -> bool:
	return not OS.has_feature("web") and not OS.has_feature("mobile") and DisplayServer.get_name() != "headless"


static func _best_scale(available: Vector2) -> float:
	var fit := minf(available.x / GameRules.SCREEN_SIZE.x, available.y / GameRules.SCREEN_SIZE.y)
	return floorf(fit) if fit >= 1.0 else fit
