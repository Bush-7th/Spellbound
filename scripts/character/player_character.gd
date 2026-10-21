class_name PlayerCharacter
extends Character

var surface_speed_multiplier: float = 1.0

@export_category("Прыжок")
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.12
@export var jumpcut_mult : float = 0.15
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

@export_category("Рывок")
@export var dash_speed: float = 700.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.40
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var facing_direction: float = 1.0
var dash_direction: float = 1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Гравитация.
	if not is_on_floor():
		velocity += get_gravity() * delta

	surface_speed_multiplier = 1.0

	# Время, в течение которого можно прыгнуть после края.
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	# Запоминаем нажатие прыжка на короткое время.
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	# Горизонтальное движение.
	var direction := Input.get_axis("move_left", "move_right")

	# Перезарядка рывка.
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)

	# Начало рывка.
	if Input.is_action_just_pressed("dash"):
		if not is_dashing and dash_cooldown_timer <= 0.0:
			perform_dash()
	# Во время рывка обычное движение и гравитация не работают.
	if is_dashing:
		velocity = Vector2(dash_direction * dash_speed, 0.0)

		move_and_slide()

		dash_timer -= delta

		# Завершаем рывок по времени или при столкновении со стеной.
		if dash_timer <= 0.0 or is_on_wall():
			finish_dash()

		_update_animation(direction)
		return

	if direction != 0.0:
		velocity.x = lerp(velocity.x,direction * move_speed * surface_speed_multiplier,20 * delta)
		facing_direction = 1 * sign(direction)
	else:
		velocity.x = lerp(velocity.x,0.0,20 * delta)

	# Прыжок с земли или сразу после схода с края.
	if jump_buffer_timer > 0.0:
		if is_on_floor() or coyote_timer > 0.0:
			perform_jump()

	# Отпустили кнопку — обрезаем подъём.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jumpcut_mult

	move_and_slide()

	# Если только что приземлились с сохранённым нажатием.
	if is_on_floor() and jump_buffer_timer > 0.0:
		perform_jump()
	
	_update_animation(direction)



func _update_animation(direction: float) -> void:
	# Определяем состояние
	var state: String

	if not is_on_floor():
		if velocity.y < 0:
			state = "jump"
		else:
			state = "fall"
	else:
		if absf(velocity.x) < 10.0:
			state = "idle"
		else:
			state = "move"

	# Меняем анимацию только если она другая (иначе будет сброс каждый кадр)
	if sprite.animation != state:
		sprite.play(state)

	# Отражение по горизонтали (смотрит влево/вправо)
	if direction > 0:
		sprite.flip_h = false
	elif direction < 0:
		sprite.flip_h = true
	# Если direction == 0 — сохраняем последнее направление



func perform_jump() -> void:
	velocity.y = -jump_speed

	# Расходуем нажатие и возможность прыжка после края.
	coyote_timer = 0.0
	jump_buffer_timer = 0.0

	# Если кнопку отпустили до приземления,
	# выполняем короткий прыжок.
	if not Input.is_action_pressed("jump"):
		velocity.y *= jumpcut_mult



func perform_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration

	# Фиксируем направление на весь рывок.
	dash_direction = facing_direction

	# Рывок расходует возможность прыжка после края.
	coyote_timer = 0.0

	# Прекращаем подъём или падение.
	velocity = Vector2(dash_direction * dash_speed, 0.0)



func finish_dash() -> void:
	is_dashing = false

	# Перезарядка начинается после окончания рывка.
	dash_cooldown_timer = dash_cooldown

	# Не оставляем персонажу скорость рывка.
	velocity.x = 0.0
