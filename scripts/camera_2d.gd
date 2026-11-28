class_name GameCamera
extends Camera2D

@export var player: PlayerCharacter
@export var default_director: CameraDirector

@export_group("Следование")
@export var follow_speed: float = 8.0
@export var vertical_follow_speed: float = 5.0
@export var vertical_offset: float = -30.0

@export_group("Мёртвая зона")
# Игрок может двигаться внутри этого прямоугольника, не двигая камеру
@export var dead_zone_size: Vector2 = Vector2(70.0, 110.0)

@export_group("Взгляд вперёд")
@export var look_ahead_distance: float = 70.0
@export var look_ahead_speed: float = 4.0
# По оси X: доля от максимальной скорости (0..1)
# По оси Y: доля look_ahead_distance (0..1)
@export var look_ahead_curve: Curve

@export_group("Взгляд вниз при падении")
@export var fall_look_distance: float = 60.0
@export var fall_speed_threshold: float = 500.0
@export var fall_look_speed: float = 3.0

@export_group("Переходы и фокус")
@export var transition_duration: float = 1.5
@export var focus_blend_time: float = 0.8

var _anchor: Vector2 = Vector2.ZERO
var _look_ahead: float = 0.0
var _look_down: float = 0.0

var _focus_target: Node2D = null
var _focus_progress: float = 0.0
var _focus_weight: float = 0.0
var _desired_focus_weight: float = 0.0

var _active_director: CameraDirector = null
var _director_requests: Dictionary = {}

var _transition_offset: Vector2 = Vector2.ZERO
var _transition_elapsed: float = 0.0
var _transitioning: bool = false
var _initialized: bool = false


func _ready() -> void:
	position_smoothing_enabled = false
	limit_smoothed = false

	drag_horizontal_enabled = false
	drag_vertical_enabled = false

	offset = Vector2.ZERO
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	ignore_rotation = true

	limit_left = -10000000
	limit_top = -10000000
	limit_right = 10000000
	limit_bottom = 10000000

	enabled = true
	make_current()


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var anchor_target: Vector2 = (
		player.global_position
		+ Vector2(0.0, vertical_offset)
	)

	if not _initialized:
		_anchor = anchor_target

	_update_dead_zone(anchor_target)
	_update_look_ahead(delta)
	_update_look_down(delta)
	_update_focus(delta)

	var director: CameraDirector = _select_director()
	var goal: Vector2 = _get_goal(director)

	if not _initialized:
		_initialized = true
		_active_director = director
		global_position = goal
		return

	if director != _active_director:
		_begin_transition(director, goal)

	if _transitioning:
		_update_transition(goal, delta)
	else:
		_follow(goal, delta)


func _smoothing(speed: float, delta: float) -> float:
	return 1.0 - exp(-speed * delta)


func _smootherstep(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


func _get_goal(director: CameraDirector) -> Vector2:
	var base: Vector2 = _anchor + Vector2(_look_ahead, _look_down)
	base = _constrain_position(base, director)

	# Фокус смешивается с уже ограниченной позицией

	if _focus_target != null:
		return base.lerp(_focus_target.global_position, _focus_weight)

	return base


func _update_dead_zone(target: Vector2) -> void:
	var half: Vector2 = dead_zone_size * 0.5
	var difference: Vector2 = target - _anchor

	_anchor.x += difference.x - clampf(difference.x, -half.x, half.x)
	_anchor.y += difference.y - clampf(difference.y, -half.y, half.y)


func _begin_transition(director: CameraDirector, goal: Vector2) -> void:
	_active_director = director
	_transition_offset = global_position - goal
	_transition_elapsed = 0.0
	_transitioning = true


func _update_transition(goal: Vector2, delta: float) -> void:
	_transition_elapsed += delta

	var duration: float = maxf(transition_duration, 0.001)
	var progress: float = clampf(_transition_elapsed / duration, 0.0, 1.0)
	var eased: float = _smootherstep(progress)

	global_position = goal + _transition_offset * (1.0 - eased)

	if progress >= 1.0:
		_transitioning = false
		global_position = goal


func _follow(goal: Vector2, delta: float) -> void:
	global_position = Vector2(
		lerpf(global_position.x, goal.x, _smoothing(follow_speed, delta)),
		lerpf(
			global_position.y,
			goal.y,
			_smoothing(vertical_follow_speed, delta)
		)
	)


func _update_look_ahead(delta: float) -> void:
	var target: float = (
		player.facing_direction
		* look_ahead_distance
		* _get_look_ahead_factor()
	)

	_look_ahead = lerpf(
		_look_ahead,
		target,
		_smoothing(look_ahead_speed, delta)
	)


func _get_look_ahead_factor() -> float:
	if look_ahead_curve == null:
		return 1.0

	var max_speed: float = maxf(player.move_speed, 1.0)
	var speed_ratio: float = clampf(
		absf(player.velocity.x) / max_speed,
		0.0,
		1.0
	)

	return look_ahead_curve.sample_baked(speed_ratio)


func _update_look_down(delta: float) -> void:
	var target: float = 0.0

	if player.velocity.y > fall_speed_threshold:
		target = fall_look_distance

	_look_down = lerpf(
		_look_down,
		target,
		_smoothing(fall_look_speed, delta)
	)


func _update_focus(delta: float) -> void:
	if not is_instance_valid(_focus_target):
		_focus_target = null
		_desired_focus_weight = 0.0

	var step: float = delta / maxf(focus_blend_time, 0.001)

	_focus_progress = move_toward(
		_focus_progress,
		_desired_focus_weight,
		step
	)

	_focus_weight = _smootherstep(_focus_progress)

	if _desired_focus_weight == 0.0 and _focus_progress == 0.0:
		_focus_target = null


func _constrain_position(
	point: Vector2,
	director: CameraDirector
) -> Vector2:
	if not is_instance_valid(director):
		return point

	var rect: Rect2 = director.get_world_bounds()
	var half_screen: Vector2 = get_viewport_rect().size / zoom * 0.5

	var min_position: Vector2 = rect.position + half_screen
	var max_position: Vector2 = rect.end - half_screen
	var center: Vector2 = rect.get_center()

	return Vector2(
		_clamp_axis(point.x, min_position.x, max_position.x, center.x),
		_clamp_axis(point.y, min_position.y, max_position.y, center.y)
	)


func _clamp_axis(
	value: float,
	min_value: float,
	max_value: float,
	center: float
) -> float:
	if min_value <= max_value:
		return clampf(value, min_value, max_value)

	return center


func enter_director_zone(
	source: Node,
	director: CameraDirector,
	priority: int
) -> void:
	if not is_instance_valid(source):
		return

	if not is_instance_valid(director):
		return

	_director_requests[source] = {
		"director": director,
		"priority": priority
	}


func exit_director_zone(source: Node) -> void:
	_director_requests.erase(source)


func _select_director() -> CameraDirector:
	var selected: CameraDirector = default_director
	var best_priority: float = -INF

	for source in _director_requests.keys():
		if not is_instance_valid(source):
			_director_requests.erase(source)
			continue

		var request: Dictionary = _director_requests[source]
		var director: CameraDirector = request["director"] as CameraDirector

		if not is_instance_valid(director):
			continue

		var priority: int = request["priority"]

		if priority > best_priority:
			best_priority = priority
			selected = director

	return selected


func set_focus(target: Node2D, weight: float = 1.0) -> void:
	if not is_instance_valid(target):
		return

	_focus_target = target
	_desired_focus_weight = clampf(weight, 0.0, 1.0)


func clear_focus(target_to_clear: Node2D = null) -> void:
	if target_to_clear == null or _focus_target == target_to_clear:
		_desired_focus_weight = 0.0
