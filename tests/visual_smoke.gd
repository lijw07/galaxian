extends SceneTree

var main: Node
var captures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://tests/output/" + label + ".png")
	captures.append(label)


func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tests/output")
	HighScoreStore.save_path = "res://tests/output/visual-scores.cfg"
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.35).timeout
	await capture("title")
	await press("ui_down")
	await press("ui_accept")
	await capture("high-scores")
	await create_timer(0.25).timeout
	await press("ui_accept")
	await create_timer(0.25).timeout
	await press("ui_accept")
	await create_timer(2.4).timeout
	await capture("gameplay")
	await press("ui_cancel")
	await capture("pause")
	await create_timer(0.25, true).timeout
	await press("ui_accept")
	await press("fire")
	await create_timer(0.16).timeout
	await capture("projectile")
	main.get_node("Game")._enter_game_over()
	await capture("game-over")
	main._on_menu_action("menu")
	for dimensions in [Vector2i(390, 844), Vector2i(1024, 768)]:
		root.size = dimensions
		await create_timer(0.2).timeout
		await capture("title-%dx%d" % [dimensions.x, dimensions.y])
	main.queue_free()
	await process_frame
	root.size = Vector2i(672, 768)
	var gallery: Node = load("res://scenes/asset_gallery.tscn").instantiate()
	root.add_child(gallery)
	await create_timer(0.1).timeout
	await capture("asset-collisions")
	gallery.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("VISUAL_SMOKE ", JSON.stringify(captures))
	quit()
