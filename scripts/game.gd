class_name Game
extends Node2D

signal game_over(final_score: int)

enum Phase { IDLE, READY, ACTIVE, PLAYER_DOWN, ROUND_CLEAR }

const READY_DURATION := 2.0
const REVEAL_STEP := 0.025
const PLAYER_DOWN_DURATION := 2.0
const ROUND_CLEAR_DURATION := 1.5
const MISSILE_SIZE := Vector2(1.0, 4.0)
const BULLET_SIZE := Vector2(1.0, 3.0)
const BULLET_MUZZLE := Vector2(0.0, 6.0)
const ALIEN_EXPLOSION_RADIUS := 9.0
const ALIEN_EXPLOSION_TIME := 0.35
const PLAYER_EXPLOSION_RADIUS := 16.0
const PLAYER_EXPLOSION_TIME := 1.2
const PLAYER_EXPLOSION_COLOR := Color("ffa030")
const POPUP_COLOR := Color("40c8ff")
const ALIEN_SCENES: Array[PackedScene] = [
	preload("res://scenes/entities/green_enemy.tscn"),
	preload("res://scenes/entities/violet_enemy.tscn"),
	preload("res://scenes/entities/red_enemy.tscn"),
	preload("res://scenes/entities/boss.tscn"),
]
const PLAYER_SHOT = preload("res://scenes/entities/player_shot.tscn")
const ENEMY_SHOT = preload("res://scenes/entities/enemy_shot.tscn")
const EXPLOSION_SCENE = preload("res://scenes/effects/explosion.tscn")

@export var hud: Hud
@export var starfield: Starfield

var _phase := Phase.IDLE
var _phase_timer := 0.0
var _reveal_timer := 0.0
var _score := 0
var _reserve_ships := 0
var _round := 0
var _extra_life_awarded := false
var _escaped_flagships := 0
var _fire_freeze := 0.0
var _aliens: Array[Alien] = []
var _hidden_aliens: Array[Alien] = []
var _bullets: Array[Projectile] = []
var _missile: Projectile

@onready var _sfx: Node = get_node("/root/Sfx")
@onready var _formation: Formation = $Formation
@onready var _director: AttackDirector = $AttackDirector
@onready var _alien_layer: Node2D = $Aliens
@onready var _projectile_layer: Node2D = $Projectiles
@onready var _effect_layer: Node2D = $Effects
@onready var _player: Player = $Player


func _ready() -> void:
	_director.dive_started.connect(_on_dive_started)
	visible = false


func start_new_game() -> void:
	stop()
	_score = 0
	_round = 0
	_reserve_ships = GameRules.STARTING_SHIPS - 1
	_extra_life_awarded = false
	_escaped_flagships = 0
	visible = true
	_sync_hud()
	_sfx.play("start")
	_begin_round()


func stop() -> void:
	_phase = Phase.IDLE
	_director.active = false
	_player.controllable = false
	_player.hide()
	_clear_field()
	_fire_freeze = 0.0
	starfield.scrolling = true
	_sfx.stop_ambience()
	hide()


func _process(delta: float) -> void:
	_fire_freeze = maxf(_fire_freeze - delta, 0.0)
	_phase_timer -= delta
	_update_missile()
	_update_bullets()
	match _phase:
		Phase.READY:
			_update_ready(delta)
		Phase.ACTIVE:
			_update_active()
		Phase.PLAYER_DOWN:
			_update_player_down()
		Phase.ROUND_CLEAR:
			if _phase_timer <= 0.0:
				_begin_round()


func _begin_round() -> void:
	_round += 1
	_clear_field()
	_formation.reset()
	_spawn_formation(mini(GameRules.BASE_FLAGSHIPS + _escaped_flagships, GameRules.MAX_FLAGSHIPS))
	_escaped_flagships = 0
	_director.prepare(_round, _aliens)
	_player.reset_to_start()
	_sync_hud()
	_enter_ready()


func _spawn_formation(flagship_count: int) -> void:
	var layout := Formation.layout(flagship_count)
	for slot in layout:
		var alien := ALIEN_SCENES[layout[slot]].instantiate() as Alien
		alien.setup(layout[slot], slot, _formation, _player)
		alien.shot_requested.connect(_on_alien_shot_requested)
		alien.escaped.connect(_on_alien_escaped)
		_alien_layer.add_child(alien)
		_aliens.append(alien)
	_hidden_aliens.assign(_aliens)
	_hidden_aliens.reverse()


func _clear_field() -> void:
	for alien in _aliens:
		alien.queue_free()
	_aliens.clear()
	_hidden_aliens.clear()
	_clear_projectiles()
	for effect in _effect_layer.get_children():
		effect.queue_free()


func _clear_projectiles() -> void:
	for bullet in _bullets:
		bullet.queue_free()
	_bullets.clear()
	if _missile != null:
		_remove_missile()


func _enter_ready() -> void:
	_phase = Phase.READY
	_phase_timer = READY_DURATION
	_reveal_timer = 0.0
	hud.message = "READY!"


func _update_ready(delta: float) -> void:
	_reveal_timer -= delta
	while _reveal_timer <= 0.0 and not _hidden_aliens.is_empty():
		var alien: Alien = _hidden_aliens.pop_back()
		alien.reveal()
		_reveal_timer += REVEAL_STEP
	if _phase_timer <= 0.0 and _hidden_aliens.is_empty():
		_enter_active()


func _enter_active() -> void:
	_phase = Phase.ACTIVE
	hud.message = ""
	_player.controllable = true
	_director.resume()
	_sfx.start_ambience()


func _update_active() -> void:
	if _player.wants_to_fire():
		_fire_missile()
	_check_ramming()


func _fire_missile() -> void:
	_missile = _spawn_projectile(_player.missile_spawn_point(), Vector2.UP * GameRules.PLAYER_MISSILE_SPEED, MISSILE_SIZE)
	_player.missile_loaded = false
	_sfx.play("shoot")


func _update_missile() -> void:
	if _missile == null:
		return
	var target := _alien_hit_by(_missile.swept_rect())
	if target != null:
		_remove_missile()
		_destroy_alien(target)
	elif _missile.position.y < GameRules.MISSILE_CEILING_Y:
		_remove_missile()


func _remove_missile() -> void:
	_missile.queue_free()
	_missile = null
	_player.missile_loaded = true


func _alien_hit_by(area: Rect2) -> Alien:
	for alien in _aliens:
		if alien.state != Alien.State.HIDDEN and alien.hit_rect().intersects(area):
			return alien
	return null


func _update_bullets() -> void:
	for bullet: Projectile in _bullets.duplicate():
		if bullet.is_off_screen():
			_remove_bullet(bullet)
		elif _player_is_vulnerable() and bullet.swept_rect().intersects(_player.hit_rect()):
			_remove_bullet(bullet)
			_kill_player()


func _remove_bullet(bullet: Projectile) -> void:
	_bullets.erase(bullet)
	bullet.queue_free()


func _player_is_vulnerable() -> bool:
	return _phase == Phase.ACTIVE


func _check_ramming() -> void:
	var rammer := _alien_hit_by(_player.hit_rect())
	if rammer == null or not rammer.is_in_flight():
		return
	_destroy_alien(rammer)
	_kill_player()


func _destroy_alien(alien: Alien) -> void:
	var points := _points_for(alien)
	var flagship_charge := alien.kind == GameRules.Kind.FLAGSHIP and alien.is_in_flight()
	_detach_from_group(alien)
	_spawn_explosion(alien.position, "alien_explosion", GameRules.KIND_COLORS[alien.kind], ALIEN_EXPLOSION_RADIUS, ALIEN_EXPLOSION_TIME)
	if flagship_charge:
		_spawn_popup(alien.position, str(points))
		_fire_freeze = GameRules.FLAGSHIP_KILL_FIRE_FREEZE
		_sfx.play("flagship_hit")
	else:
		_sfx.play("alien_hit")
	_add_score(points)
	_remove_alien(alien)


func _points_for(alien: Alien) -> int:
	if not alien.is_in_flight():
		return GameRules.CONVOY_POINTS[alien.kind]
	if alien.kind == GameRules.Kind.FLAGSHIP:
		return GameRules.flagship_charger_points(alien.escorts.size(), alien.escorts_shot)
	return GameRules.CHARGER_POINTS[alien.kind]


func _detach_from_group(alien: Alien) -> void:
	if is_instance_valid(alien.leader):
		alien.leader.lose_escort(alien)
	alien.scatter_escorts()


func _remove_alien(alien: Alien) -> void:
	_aliens.erase(alien)
	alien.queue_free()
	if _aliens.is_empty() and _phase == Phase.ACTIVE:
		_enter_round_clear()


func _enter_round_clear() -> void:
	_phase = Phase.ROUND_CLEAR
	_phase_timer = ROUND_CLEAR_DURATION
	_player.controllable = false
	_director.active = false
	_clear_projectiles()
	_sfx.stop_ambience()


func _kill_player() -> void:
	_player.controllable = false
	_player.visible = false
	_spawn_explosion(_player.position, "player_explosion", PLAYER_EXPLOSION_COLOR, PLAYER_EXPLOSION_RADIUS, PLAYER_EXPLOSION_TIME)
	_sfx.play("player_hit")
	_sfx.stop_ambience()
	_director.suspend()
	starfield.scrolling = false
	_phase = Phase.PLAYER_DOWN
	_phase_timer = PLAYER_DOWN_DURATION


func _update_player_down() -> void:
	if _phase_timer > 0.0 or not _aliens_settled():
		return
	starfield.scrolling = true
	if _reserve_ships <= 0:
		_enter_game_over()
		return
	_reserve_ships -= 1
	if _aliens.is_empty():
		_begin_round()
		return
	_clear_projectiles()
	_player.reset_to_start()
	_sync_hud()
	_enter_ready()


func _aliens_settled() -> bool:
	return _aliens.all(func(alien: Alien) -> bool: return alien.is_in_formation())


func _enter_game_over() -> void:
	_sync_hud()
	_phase = Phase.IDLE
	_clear_field()
	visible = false
	game_over.emit(_score)


func _add_score(points: int) -> void:
	_score += points
	if not _extra_life_awarded and _score >= GameRules.EXTRA_LIFE_SCORE:
		_extra_life_awarded = true
		_reserve_ships += 1
		_sfx.play("extra_life")
	_sync_hud()


func _sync_hud() -> void:
	hud.score = _score
	hud.high_score = maxi(hud.high_score, _score)
	hud.reserve_ships = _reserve_ships
	hud.round_number = _round


func _spawn_projectile(start: Vector2, velocity: Vector2, size: Vector2) -> Projectile:
	var projectile := (PLAYER_SHOT if velocity.y < 0.0 else ENEMY_SHOT).instantiate() as Projectile
	projectile.setup(start, velocity, size)
	_projectile_layer.add_child(projectile)
	return projectile


func _spawn_explosion(at: Vector2, sprite_name: String, color: Color, radius: float, duration: float) -> void:
	var explosion := EXPLOSION_SCENE.instantiate() as Explosion
	explosion.position = at
	explosion.setup(sprite_name, color, radius, duration)
	_effect_layer.add_child(explosion)


func _spawn_popup(at: Vector2, text: String) -> void:
	var popup := ScorePopup.new()
	popup.position = at
	popup.setup(text, POPUP_COLOR)
	_effect_layer.add_child(popup)


func _on_alien_shot_requested(alien: Alien) -> void:
	if _phase != Phase.ACTIVE or _fire_freeze > 0.0:
		return
	if _bullets.size() >= GameRules.max_alien_bullets(_round):
		return
	var drop_time := maxf((GameRules.PLAYER_Y - alien.position.y) / GameRules.ALIEN_BULLET_SPEED, 0.1)
	var aim_x := _player.position.x + randf_range(-GameRules.ALIEN_BULLET_SPREAD, GameRules.ALIEN_BULLET_SPREAD)
	var drift := clampf((aim_x - alien.position.x) / drop_time, -GameRules.ALIEN_BULLET_MAX_DRIFT, GameRules.ALIEN_BULLET_MAX_DRIFT)
	var velocity := Vector2(drift, GameRules.ALIEN_BULLET_SPEED)
	_bullets.append(_spawn_projectile(alien.position + BULLET_MUZZLE, velocity, BULLET_SIZE))


func _on_alien_escaped(alien: Alien) -> void:
	_escaped_flagships += 1
	_detach_from_group(alien)
	_remove_alien(alien)


func _on_dive_started(_alien: Alien) -> void:
	_sfx.play("dive")
