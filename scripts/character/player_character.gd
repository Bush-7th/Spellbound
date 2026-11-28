class_name PlayerCharacter
extends Character

signal health_changed(current: int, maximum: int)
signal stamina_changed(current: float, maximum: float)

@export var max_stamina: float = 100.0
@export var stamina_regeneration_delay: float = 3.0
@export var stamina_regeneration: float = 20.0
@export var damage_cooldown: float = 0.5

@export_category("Прыжок")
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.12
@export var jumpcut_mult: float = 0.15

@export_category("Рывок")
@export var dash_speed: float = 700.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.40

@export_category("Уклонение")
@export var dodge_speed: float = 320.0
@export var dodge_jump_speed: float = 180.0
@export var dodge_deceleration: float = 1000.0
@export var dodge_duration: float = 0.30
@export var dodge_cooldown: float = 0.45

var health: int:
	set(value):
		health = clampi(value, 0, max_health)
		health_changed.emit(health, max_health)

var stamina: float:
	set(value):
		stamina = clampf(value, 0.0, max_stamina)
		stamina_changed.emit(stamina, max_stamina)

var hurt_animation_timer: float = 0.0
var damage_cooldown_timer: float = 0.0
var stamina_regeneration_timer: float = 0.0
var surface_speed_multiplier: float = 1.0
var air_dash: bool = true

var facing_direction: float = 1.0

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: float = 1.0

var is_dodging: bool = false
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0

var _last_grounded_time: float = -INF
var _input_buffer: InputBuffer = InputBuffer.new([&"jump"])

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	health = max_health
	stamina = max_stamina


func _physics_process(delta: float) -> void:
	var current_time: float = SceneClock.time

	up_direction = _get_up_direction()

	_update_timers(delta)
	update_stamina_regeneration(delta)
	_input_buffer.update(current_time)

	var direction := Input.get_axis(&"move_left", &"move_right")

	_try_start_dodge(direction)

	if is_dodging:
		_process_dodge(delta)
		return

	_update_ground_state(current_time)
	_update_surface_speed()

	_try_start_dash()

	if is_dashing:
		_process_dash(delta)
		_update_animation(direction)
		return

	_apply_gravity(delta)
	_update_horizontal_movement(direction, delta)

	_try_jump(current_time)
	_apply_jump_cut()

	move_and_slide()

	if is_on_floor():
		_try_jump(current_time)

	_update_animation(direction)


# Гравитация и вертикальная скорость

func _get_up_direction() -> Vector2:
	var gravity: Vector2 = get_gravity()

	if gravity.is_zero_approx():
		return up_direction

	return -gravity.normalized()


# Положительное значение — движение вверх относительно гравитации
func get_upward_speed() -> float:
	return velocity.dot(up_direction)


func _set_upward_speed(speed: float) -> void:
	velocity += up_direction * (speed - get_upward_speed())


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func _update_timers(delta: float) -> void:
	dodge_cooldown_timer = maxf(dodge_cooldown_timer - delta, 0.0)
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	hurt_animation_timer = maxf(hurt_animation_timer - delta, 0.0)
	damage_cooldown_timer = maxf(damage_cooldown_timer - delta, 0.0)


func _update_ground_state(current_time: float) -> void:
	if is_on_floor():
		_last_grounded_time = current_time
		air_dash = true


func _update_horizontal_movement(direction: float, delta: float) -> void:
	var target_speed := direction * move_speed * surface_speed_multiplier

	velocity.x = lerpf(
		velocity.x,
		target_speed,
		clampf(20.0 * delta, 0.0, 1.0)
	)

	if direction != 0.0:
		facing_direction = signf(direction)


func _cancel_coyote_jump() -> void:
	_last_grounded_time = -INF


func _cancel_buffered_jump() -> void:
	_input_buffer.clear_action(&"jump")


func _spend_stamina(amount: float) -> void:
	stamina -= amount
	stamina_regeneration_timer = stamina_regeneration_delay


# Прыжок

func _try_jump(current_time: float) -> void:
	var can_jump := (
		is_on_floor()
		or current_time - _last_grounded_time <= coyote_time
	)

	if not can_jump:
		return

	if not _input_buffer.consume(&"jump", jump_buffer_time, current_time):
		return

	_cancel_coyote_jump()
	perform_jump()


func perform_jump() -> void:
	_set_upward_speed(jump_speed)

	if not Input.is_action_pressed(&"jump"):
		_set_upward_speed(get_upward_speed() * jumpcut_mult)


func _apply_jump_cut() -> void:
	if not Input.is_action_just_released(&"jump"):
		return

	var upward_speed: float = get_upward_speed()

	if upward_speed > 0.0:
		_set_upward_speed(upward_speed * jumpcut_mult)


# Рывок

func _try_start_dash() -> void:
	if not Input.is_action_just_pressed(&"dash"):
		return

	if not _can_dash():
		return

	_cancel_coyote_jump()
	_spend_stamina(30.0)
	perform_dash()


func _can_dash() -> bool:
	return (
		not is_dashing
		and not is_dodging
		and dash_cooldown_timer <= 0.0
		and stamina >= 30.0
		and (is_on_floor() or air_dash)
	)


func perform_dash() -> void:
	if not is_on_floor():
		air_dash = false

	is_dashing = true
	dash_timer = dash_duration
	dash_direction = facing_direction

	velocity = Vector2(dash_direction * dash_speed, 0.0)


func _process_dash(delta: float) -> void:
	velocity = Vector2(dash_direction * dash_speed, 0.0)

	move_and_slide()

	dash_timer = maxf(dash_timer - delta, 0.0)

	if dash_timer <= 0.0 or is_on_wall():
		finish_dash()


func finish_dash() -> void:
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown_timer = dash_cooldown

	# Игрок сразу управляет персонажем: скорость рывка
	var run_speed: float = move_speed * surface_speed_multiplier
	velocity.x = clampf(velocity.x, -run_speed, run_speed)


# Уклонение

func _try_start_dodge(direction: float) -> void:
	if not Input.is_action_just_pressed(&"dodge"):
		return

	if not _can_dodge():
		return

	if direction != 0.0:
		facing_direction = signf(direction)

	_cancel_coyote_jump()
	_cancel_buffered_jump()
	_spend_stamina(20.0)
	perform_dodge()


func _can_dodge() -> bool:
	return (
		is_on_floor()
		and not is_dashing
		and not is_dodging
		and dodge_cooldown_timer <= 0.0
		and stamina >= 20.0
	)


func perform_dodge() -> void:
	is_dodging = true
	dodge_timer = dodge_duration

	velocity = Vector2(-facing_direction * dodge_speed, 0.0)
	_set_upward_speed(dodge_jump_speed)

	sprite.flip_h = facing_direction < 0.0


func _process_dodge(delta: float) -> void:
	dodge_timer = maxf(dodge_timer - delta, 0.0)

	velocity += get_gravity() * delta
	velocity.x = move_toward(velocity.x, 0.0, dodge_deceleration * delta)

	move_and_slide()

	if dodge_timer <= 0.0 or is_on_floor():
		finish_dodge()


func finish_dodge() -> void:
	is_dodging = false
	dodge_timer = 0.0
	dodge_cooldown_timer = dodge_cooldown


# Поверхность и анимация

func _update_surface_speed() -> void:
	surface_speed_multiplier = 1.0

	if not is_on_floor():
		return

	var surface_found := false

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var normal := collision.get_normal()

		if normal.dot(up_direction) < cos(floor_max_angle):
			continue

		var tile_layer := collision.get_collider() as TileMapLayer

		if tile_layer == null:
			continue

		if tile_layer.tile_set == null:
			continue

		if tile_layer.tile_set.get_custom_data_layer_by_name("speed_mult") == -1:
			continue

		var cell := tile_layer.get_coords_for_body_rid(
			collision.get_collider_rid()
		)

		var tile_data := tile_layer.get_cell_tile_data(cell)

		if tile_data == null:
			continue

		var multiplier: float = tile_data.get_custom_data("speed_mult")

		if not surface_found:
			surface_speed_multiplier = multiplier
			surface_found = true
		else:
			surface_speed_multiplier = minf(
				surface_speed_multiplier,
				multiplier
			)


func _update_animation(direction: float) -> void:
	if hurt_animation_timer > 0.0:
		return

	var state: String

	if not is_on_floor():
		state = "jump" if get_upward_speed() > 0.0 else "fall"
	elif absf(velocity.x) < 10.0:
		state = "idle"
	else:
		state = "move"

	if sprite.animation != state:
		sprite.play(state)

	if direction > 0.0:
		sprite.flip_h = false
	elif direction < 0.0:
		sprite.flip_h = true


# Здоровье и стамина

func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return

	if damage_cooldown_timer > 0.0:
		return

	damage_cooldown_timer = damage_cooldown
	health -= amount

	if health <= 0:
		queue_free()
		return

	if sprite.sprite_frames.has_animation("take_damage"):
		hurt_animation_timer = 0.1
		sprite.play("take_damage")


func update_stamina_regeneration(delta: float) -> void:
	if stamina_regeneration_timer > 0.0:
		stamina_regeneration_timer = maxf(
			stamina_regeneration_timer - delta,
			0.0
		)
		return

	if stamina >= max_stamina:
		return

	stamina += stamina_regeneration * delta
