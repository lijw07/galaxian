class_name AttackDirector
extends Node

signal dive_started(alien: Alien)

const SWARM_LAUNCH_FACTOR := 0.35
const EDGE_DEPTH := 1
const ESCORT_COLUMN_REACH := 1
const MAX_ESCORTS := 2

var active := false

var _aliens: Array[Alien] = []
var _round := 1
var _launch_timer := 0.0
var _flagship_timer := 0.0
var _next_side := -1
var _swarm := false


func prepare(round_number: int, aliens: Array[Alien]) -> void:
	_round = round_number
	_aliens = aliens
	_swarm = false
	active = false


func resume() -> void:
	active = true
	_launch_timer = GameRules.launch_interval(_round)
	_flagship_timer = GameRules.flagship_interval(_round)


func suspend() -> void:
	active = false
	_swarm = false
	for alien in _aliens:
		alien.keep_attacking = false


func _process(delta: float) -> void:
	if not active or _aliens.is_empty():
		return
	_update_swarm()
	_flagship_timer -= delta
	_launch_timer -= delta
	if _flagship_timer <= 0.0:
		_flagship_timer = GameRules.flagship_interval(_round)
		_launch_flagship_group()
	if _launch_timer <= 0.0:
		_launch_timer = GameRules.launch_interval(_round) * (SWARM_LAUNCH_FACTOR if _swarm else 1.0)
		_launch_chargers()


func _update_swarm() -> void:
	if _swarm or not _should_swarm():
		return
	_swarm = true
	for alien in _aliens:
		alien.keep_attacking = true


func _should_swarm() -> bool:
	if _aliens.size() <= GameRules.SWARM_ALIVE_THRESHOLD:
		return true
	return not _aliens.any(_is_drone)


func _is_drone(alien: Alien) -> bool:
	return alien.kind == GameRules.Kind.BLUE or alien.kind == GameRules.Kind.PURPLE


func _launch_chargers() -> void:
	if not _swarm and _solo_chargers_in_flight() >= GameRules.max_chargers(_round):
		return
	var side := _next_side
	_next_side = -_next_side
	var group_size := 2 if randf() < GameRules.gang_chance(_round) else 1
	for _index in group_size:
		var alien := _pick_edge_alien(side)
		if alien == null:
			return
		_launch(alien)


func _launch(alien: Alien) -> void:
	alien.launch(GameRules.dive_speed(_round), GameRules.shots_per_dive(_round))
	dive_started.emit(alien)


func _solo_chargers_in_flight() -> int:
	return _aliens.filter(func(alien: Alien) -> bool: return alien.is_in_flight() and alien.leader == null).size()


func _pick_edge_alien(side: int) -> Alien:
	var candidates := _aliens.filter(_can_charge_alone)
	if candidates.is_empty():
		return null
	var edge: int = candidates.map(func(alien: Alien) -> int: return alien.slot.x * side).max()
	var edge_group := candidates.filter(func(alien: Alien) -> bool: return alien.slot.x * side >= edge - EDGE_DEPTH)
	return edge_group.pick_random()


func _can_charge_alone(alien: Alien) -> bool:
	if not alien.is_in_formation():
		return false
	if _swarm or _is_drone(alien):
		return true
	return alien.kind == GameRules.Kind.RED and not _aliens.any(_is_flagship)


func _is_flagship(alien: Alien) -> bool:
	return alien.kind == GameRules.Kind.FLAGSHIP


func _launch_flagship_group() -> void:
	if _swarm or _aliens.any(func(alien: Alien) -> bool: return _is_flagship(alien) and alien.is_in_flight()):
		return
	var waiting := _aliens.filter(func(alien: Alien) -> bool: return _is_flagship(alien) and alien.is_in_formation())
	if waiting.is_empty():
		return
	var flagship: Alien = waiting.pick_random()
	var escorts := _escorts_for(flagship)
	_launch(flagship)
	var taken_side := 0.0
	for escort in escorts:
		var side := -signf(escort.slot.x - flagship.slot.x)
		if side == 0.0:
			side = -taken_side if taken_side != 0.0 else 1.0
		taken_side = side
		escort.follow(flagship, side, GameRules.dive_speed(_round), GameRules.shots_per_dive(_round))


func _escorts_for(flagship: Alien) -> Array[Alien]:
	var escorts: Array[Alien] = []
	escorts.assign(_aliens.filter(func(alien: Alien) -> bool: return _is_available_escort(alien, flagship)))
	escorts.sort_custom(func(a: Alien, b: Alien) -> bool: return absi(a.slot.x - flagship.slot.x) > absi(b.slot.x - flagship.slot.x))
	escorts.resize(mini(escorts.size(), MAX_ESCORTS))
	return escorts


func _is_available_escort(alien: Alien, flagship: Alien) -> bool:
	var close_enough := absi(alien.slot.x - flagship.slot.x) <= ESCORT_COLUMN_REACH
	return alien.kind == GameRules.Kind.RED and alien.is_in_formation() and close_enough
