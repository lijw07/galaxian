extends SceneTree

var checks := 0
var failures: Array[String] = []
var _main: Node


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tests/output")
	HighScoreStore.save_path = "res://tests/output/test-scores.cfg"
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/approved/manifest.json"))
	for entry: Dictionary in manifest.roster:
		check(FileAccess.get_sha256("res://" + entry.path) == entry.sha256, "Asset digest: " + entry.path)
	for pair in [["player", "player-ship"], ["alien_blue", "green-enemy"], ["alien_purple", "violet-enemy"], ["alien_red", "red-enemy"], ["alien_flagship", "boss"]]:
		var sheet: Image = load("res://assets/sprites/%s.png" % pair[0]).get_image()
		check(sheet.get_size() == Vector2i(72, 24), "Three frame strip: " + pair[0])
		for frame in 3:
			var approved: Image = load("res://assets/approved/frames/%s-%d.png" % [pair[1], frame + 1]).get_image()
			var matches := true
			var symmetric := true
			for y in 24:
				for x in 24:
					matches = matches and sheet.get_pixel(frame * 24 + x, y) == approved.get_pixel(x, y)
					symmetric = symmetric and approved.get_pixel(x, y) == approved.get_pixel(23 - x, y)
			check(matches, "Approved bytes preserved in frame " + pair[0] + str(frame))
			check(symmetric, "Symmetric frame " + pair[0] + str(frame))
	await _check_physics()
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	var game: Game = _main.get_node("Game")
	var music: Node = root.get_node("Music")
	check(_main.get_node("TitleScreen").visible, "Title opens")
	check(not _main.get_node("Hud").visible, "Title has no gameplay HUD")
	check(music.current_track == "title", "Title music")
	check(music._player.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Title loops")
	check(_main.get_node("TitleScreen").options == PackedStringArray(["START GAME", "HIGH SCORES", "QUIT"]), "Single-player menu")
	_main.get_node("TitleScreen")._choose(0)
	await process_frame
	check(game.visible and game._aliens.size() == 46, "Playable formation instantiated from scenes")
	check(music.current_track == "gameplay", "Gameplay music")
	game._phase_timer = 0.0
	game._update_ready(3.0)
	check(game._phase == Game.Phase.ACTIVE and game._player.controllable, "Ready enters active")
	await physics_frame
	await physics_frame
	check(not game._player.get_node("CollisionShape2D").disabled, "Player collider enabled in play")
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	_main._unhandled_input(cancel)
	check(paused and _main.get_node("PauseMenu").visible, "Pause opens")
	var before: Vector2 = game._aliens[0].position
	await create_timer(0.08, true).timeout
	check(game._aliens[0].position == before, "Pause freezes gameplay")
	check(music._player.stream_paused, "Pause freezes music")
	_main.get_node("PauseMenu")._choose(0)
	check(not paused and not music._player.stream_paused, "Resume restores music and simulation")
	game.set_process(false)
	game._director.active = false
	for alien in game._aliens:
		alien.set_process(false)
	var target: Alien = game._aliens[0]
	target.position = Vector2(game._player.position.x, 182)
	var count := game._aliens.size()
	game._fire_missile()
	game._missile.set_process(false)
	game._missile._process(0.2)
	game._update_missile()
	check(game._aliens.size() == count - 1 and game._score > 0, "Fast swept projectile damages enemy")
	check(game._missile == null and game._player.missile_loaded, "Hit reloads single player shot")
	var shot: Projectile = game.ENEMY_SHOT.instantiate()
	shot.setup(game._player.position + Vector2(0, -20), Vector2(0, 200), Vector2(1, 3))
	game._projectile_layer.add_child(shot)
	game._bullets.append(shot)
	shot.set_process(false)
	shot._process(0.15)
	game._update_bullets()
	check(game._phase == Game.Phase.PLAYER_DOWN and not game._player.visible, "Enemy bullet kills player")
	await physics_frame
	await physics_frame
	check(game._player.get_node("CollisionShape2D").disabled, "Dead player collision disabled")
	game._enter_game_over()
	check(_main.get_node("GameOverMenu").visible and not game.visible, "Game-over menu replaces playfield")
	check(music.current_track == "game_over" and music._player.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Game-over cue does not loop")
	_main.get_node("GameOverMenu")._choose(0)
	check(game._score == 0 and game._round == 1 and game._aliens.size() == 46, "Replay starts clean")
	_main._on_menu_action("menu")
	check(game._aliens.is_empty() and not game.visible and _main.get_node("TitleScreen").visible, "Return to menu cleans up")
	_main.get_node("TitleScreen")._choose(1)
	check(_main.get_node("HighScores").visible, "High score menu opens")
	_main.get_node("HighScores")._choose(0)
	check(_main.get_node("TitleScreen").visible, "High score back")
	_main.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	var report := {"checks": checks, "failures": failures}
	var file := FileAccess.open("res://tests/output/integration.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("ASSET_INTEGRATION ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)


func _check_physics() -> void:
	var bodies: Array[Area2D] = []
	var names := ["player", "green_enemy", "violet_enemy", "red_enemy", "boss", "player_shot", "enemy_shot"]
	for name in names:
		var body: Area2D = load("res://scenes/entities/%s.tscn" % name).instantiate()
		root.add_child(body)
		body.set_process(false)
		body.position = Vector2(100, 100)
		body.get_node("CollisionShape2D").set_deferred("disabled", false)
		check(body.get_node("Visual").texture != null, "Visible scene: " + name)
		check(body.get_node("CollisionShape2D").shape is RectangleShape2D, "Editable rectangle collider: " + name)
		bodies.append(body)
	await physics_frame
	await physics_frame
	await physics_frame
	check(bodies[5].overlaps_area(bodies[1]), "Player shot detects enemy via physics")
	check(not bodies[5].overlaps_area(bodies[0]), "Player shot ignores player")
	check(bodies[6].overlaps_area(bodies[0]), "Enemy shot detects player via physics")
	check(not bodies[6].overlaps_area(bodies[1]), "Enemy shot ignores enemies")
	check(bodies[0].overlaps_area(bodies[4]), "Player detects enemy ramming")
	var collider_a: Shape2D = bodies[1].get_node("CollisionShape2D").shape
	var duplicate: Area2D = load("res://scenes/entities/green_enemy.tscn").instantiate()
	check(collider_a != duplicate.get_node("CollisionShape2D").shape, "Collision resources are instance-local")
	duplicate.free()
	for body in bodies:
		body.queue_free()
	await process_frame
