class_name Alien
extends Area2D

signal shot_requested(alien: Alien)
signal escaped(alien: Alien)

enum State { HIDDEN, FORMATION, PEELING, DIVING, ESCORTING, RETURNING }

const DOWN := PI / 2.0
const BODY_SIZE := Vector2(12.0, 9.0)
const FLAP_SEQUENCE: Array[int] = [0, 1, 2, 1]
const FLAP_INTERVAL := 0.14
const PEEL_TURN_RATE := 4.2
const PEEL_SPEED_FACTOR := 0.7
const RETURN_SPEED_FACTOR := 0.9
const SCATTER_TURN_FACTOR := 1.6
const HEADING_LIMIT := 1.15
const WALL_MARGIN := 6.0
const OFFSCREEN_MARGIN := 12.0
const ESCORT_OFFSET := Vector2(13.0, -9.0)
const ESCORT_SETTLE_SPEED := 24.0
const WANDER_INTERVAL := 0.5
const TOP_FIRE_Y := 48.0
const SHOT_DELAY_MIN := 0.25
const SHOT_DELAY_MAX := 0.9

@export var kind: GameRules.Kind = GameRules.Kind.BLUE
var slot := Vector2i.ZERO
var state := State.HIDDEN:
	set(value):
		state = value
		if has_node("CollisionShape2D"):
			$CollisionShape2D.set_deferred("disabled", value == State.HIDDEN)
var heading := DOWN
var keep_attacking := false
var leader: Alien
var escorts: Array[Alien] = []
var escorts_shot := 0

var _formation: Formation
var _target: Node2D
@onready var _visual: ArcadeSprite = $Visual
var _speed := 0.0
var _turn_rate := 0.0
var _turn_direction := 1.0
var _turned := 0.0
var _wander := 0.0
var _wander_timer := 0.0
var _shots_per_pass := 0
var _shots_left := 0
var _shot_timer := 0.0
var _flap_clock := 0.0
var _escort_offset := Vector2.ZERO
var _escort_target := Vector2.ZERO


func setup(alien_kind: GameRules.Kind, formation_slot: Vector2i, formation: Formation, target: Node2D) -> void:
	kind = alien_kind
	slot = formation_slot
	_formation = formation
	_target = target
	_turn_rate = GameRules.DIVE_TURN_RATES[kind]
	_flap_clock = slot.x * FLAP_INTERVAL * 0.5
	_visual = $Visual
	_visual.setup(GameRules.KIND_SPRITES[kind], GameRules.KIND_COLORS[kind], BODY_SIZE, ArcadeSprite.Shape.WEDGE_DOWN)
	position = formation.slot_position(slot)
	visible = false


func reveal() -> void:
	state = State.FORMATION
	visible = true


func is_in_formation() -> bool:
	return state == State.FORMATION


func is_in_flight() -> bool:
	return state != State.FORMATION and state != State.HIDDEN


func hit_rect() -> Rect2:
	var shape: RectangleShape2D = $CollisionShape2D.shape
	return Rect2(position + $CollisionShape2D.position - shape.size / 2.0, shape.size)


func launch(speed: float, shots: int) -> void:
	_arm(speed, shots)
	state = State.PEELING
	heading = -DOWN
	_turned = 0.0
	_turn_direction = -1.0 if position.x < GameRules.SCREEN_SIZE.x / 2.0 else 1.0


func follow(flagship: Alien, side: float, speed: float, shots: int) -> void:
	_arm(speed, shots)
	state = State.ESCORTING
	leader = flagship
	flagship.escorts.append(self)
	_escort_offset = (position - flagship.position).rotated(-_leader_rotation())
	_escort_target = Vector2(ESCORT_OFFSET.x * side, ESCORT_OFFSET.y)


func scatter() -> void:
	leader = null
	state = State.DIVING
	heading = wrapf(heading, -PI, PI)
	_turn_rate = GameRules.DIVE_TURN_RATES[kind] * SCATTER_TURN_FACTOR
	_pick_wander()


func scatter_escorts() -> void:
	for escort in escorts:
		escort.scatter()
	escorts.clear()


func lose_escort(escort: Alien) -> void:
	escorts.erase(escort)
	escorts_shot += 1


func return_home() -> void:
	leader = null
	state = State.RETURNING


func _arm(speed: float, shots: int) -> void:
	_speed = speed
	_shots_per_pass = shots
	_turn_rate = GameRules.DIVE_TURN_RATES[kind]
	escorts.clear()
	escorts_shot = 0
	_reload()


func _reload() -> void:
	_shots_left = _shots_per_pass
	_shot_timer = randf_range(SHOT_DELAY_MIN, SHOT_DELAY_MAX)


func _process(delta: float) -> void:
	_flap(delta)
	if _formation == null:
		return
	match state:
		State.FORMATION:
			position = _formation.slot_position(slot)
		State.PEELING:
			_peel(delta)
		State.DIVING:
			_dive(delta)
		State.ESCORTING:
			_escort(delta)
		State.RETURNING:
			_return_home(delta)
	_visual.rotation = heading - DOWN if is_in_flight() else 0.0
	_update_shooting(delta)


func _flap(delta: float) -> void:
	_flap_clock += delta
	var step := floori(_flap_clock / FLAP_INTERVAL) % FLAP_SEQUENCE.size()
	_visual.show_frame(FLAP_SEQUENCE[step])


func _peel(delta: float) -> void:
	var step := PEEL_TURN_RATE * delta
	heading += step * _turn_direction
	_turned += step
	_advance(delta, _speed * PEEL_SPEED_FACTOR)
	if _turned >= PI:
		heading = DOWN
		state = State.DIVING
		_pick_wander()


func _dive(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_wander()
	if position.y < GameRules.FIRE_CEILING_Y:
		_steer_toward(Vector2(_target.position.x + _wander, GameRules.PLAYER_Y), delta)
	_advance(delta, _speed)
	_bounce_off_walls()
	if position.y > GameRules.SCREEN_SIZE.y + OFFSCREEN_MARGIN:
		_leave_bottom()


func _steer_toward(aim: Vector2, delta: float) -> void:
	var desired := clampf((aim - position).angle(), DOWN - HEADING_LIMIT, DOWN + HEADING_LIMIT)
	heading = move_toward(heading, desired, _turn_rate * delta)


func _pick_wander() -> void:
	var reach := GameRules.WANDER_RANGES[kind]
	_wander = randf_range(-reach, reach)
	_wander_timer = WANDER_INTERVAL


func _advance(delta: float, speed: float) -> void:
	position += Vector2.from_angle(heading) * speed * delta


func _bounce_off_walls() -> void:
	var moving_left := cos(heading) < 0.0
	var at_left_wall := position.x < WALL_MARGIN and moving_left
	var at_right_wall := position.x > GameRules.SCREEN_SIZE.x - WALL_MARGIN and not moving_left
	if at_left_wall or at_right_wall:
		heading = PI - heading


func _leave_bottom() -> void:
	if kind == GameRules.Kind.FLAGSHIP and keep_attacking:
		escaped.emit(self)
		return
	position.y = -OFFSCREEN_MARGIN
	heading = DOWN
	_reload()
	if not keep_attacking:
		state = State.RETURNING


func _escort(delta: float) -> void:
	if not is_instance_valid(leader):
		scatter()
		return
	_escort_offset = _escort_offset.move_toward(_escort_target, ESCORT_SETTLE_SPEED * delta)
	heading = leader.heading
	position = leader.position + _escort_offset.rotated(_leader_rotation())


func _leader_rotation() -> float:
	return leader.heading - DOWN


func _return_home(delta: float) -> void:
	var home := _formation.slot_position(slot)
	var step := _speed * RETURN_SPEED_FACTOR * delta
	if position.distance_to(home) <= step:
		_dock(home)
		return
	heading = (home - position).angle()
	position = position.move_toward(home, step)


func _dock(home: Vector2) -> void:
	position = home
	heading = DOWN
	state = State.FORMATION
	_shots_left = 0
	for escort in escorts:
		escort.return_home()
	escorts.clear()


func _update_shooting(delta: float) -> void:
	if _shots_left <= 0 or not _in_firing_band():
		return
	_shot_timer -= delta
	if _shot_timer > 0.0:
		return
	_shots_left -= 1
	_shot_timer = randf_range(SHOT_DELAY_MIN, SHOT_DELAY_MAX)
	shot_requested.emit(self)


func _in_firing_band() -> bool:
	return _is_attacking() and position.y > TOP_FIRE_Y and position.y < GameRules.FIRE_CEILING_Y


func _is_attacking() -> bool:
	if state == State.ESCORTING:
		return is_instance_valid(leader) and leader.state == State.DIVING
	return state == State.DIVING
