class_name GameRules
extends RefCounted

enum Kind { BLUE, PURPLE, RED, FLAGSHIP }

const SCREEN_SIZE := Vector2(224.0, 256.0)
const PLAYER_Y := 222.0
const PLAYER_SPEED := 84.0
const PLAYER_MISSILE_SPEED := 280.0
const MISSILE_CEILING_Y := 12.0
const ALIEN_BULLET_SPEED := 110.0
const ALIEN_BULLET_MAX_DRIFT := 45.0
const ALIEN_BULLET_SPREAD := 14.0
const FIRE_CEILING_Y := 178.0
const EXTRA_LIFE_SCORE := 7000
const STARTING_SHIPS := 3
const BASE_FLAGSHIPS := 2
const MAX_FLAGSHIPS := 4
const FLAGSHIP_KILL_FIRE_FREEZE := 2.5
const SWARM_ALIVE_THRESHOLD := 3

const KIND_SPRITES: Array[String] = ["alien_blue", "alien_purple", "alien_red", "alien_flagship"]
const KIND_COLORS: Array[Color] = [Color("3c7cff"), Color("c050ff"), Color("ff3c3c"), Color("ffd83c")]
const CONVOY_POINTS: Array[int] = [30, 40, 50, 60]
const CHARGER_POINTS: Array[int] = [60, 80, 100, 150]
const DIVE_TURN_RATES: Array[float] = [1.0, 2.1, 1.5, 1.4]
const WANDER_RANGES: Array[float] = [18.0, 56.0, 24.0, 10.0]


static func flagship_charger_points(escorts_flying: int, escorts_shot: int) -> int:
	if escorts_shot >= 2:
		return 800
	if escorts_flying >= 2:
		return 300
	if escorts_flying == 1:
		return 200
	return 150


static func dive_speed(round_number: int) -> float:
	return minf(68.0 + 5.0 * (round_number - 1), 110.0)


static func launch_interval(round_number: int) -> float:
	return maxf(2.4 - 0.2 * (round_number - 1), 0.8)


static func flagship_interval(round_number: int) -> float:
	return maxf(9.0 - 0.7 * (round_number - 1), 4.0)


static func max_chargers(round_number: int) -> int:
	return mini(2 + floori(round_number / 2.0), 5)


static func shots_per_dive(round_number: int) -> int:
	return mini(1 + floori(round_number / 2.0), 4)


static func gang_chance(round_number: int) -> float:
	return clampf(0.12 * (round_number - 2), 0.0, 0.6)


static func max_alien_bullets(round_number: int) -> int:
	return mini(3 + floori(round_number / 3.0), 6)
