class_name PlayerCharacter
extends Character

var hurt_animation_timer : float =  0
var health: int
var can_take_damage := true
@export var spike_damage_cooldown: float = 0.5
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

@export_category("Уклонение")
@export var dodge_speed: float = 320.0
@export var dodge_jump_speed: float = 180.0
@export var dodge_deceleration: float = 1000.0
@export var dodge_duration: float = 0.30
@export var dodge_cooldown: float = 0.45
var is_dodging: bool = false
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $UI/HealthBar

#изменение хп
func _ready() -> void:
	health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health


func _physics_process(delta: float) -> void:
	# Перезарядка уклонения
	dodge_cooldown_timer = maxf(dodge_cooldown_timer - delta,0.0)
	hurt_animation_timer = maxf(hurt_animation_timer - delta, 0.0)

	# уклон
	if Input.is_action_just_pressed("dodge"):
		if (is_on_floor() and not is_dashing and not is_dodging and dodge_cooldown_timer == 0.0):
			var input_direction := Input.get_axis("move_left","move_right")
			if input_direction != 0.0:
				facing_direction = signf(input_direction)
			perform_dodge()
	if is_dodging:
		_process_dodge(delta)
		return

	# гравитация
	if not is_on_floor():
		velocity += get_gravity() * delta

	_update_surface_speed()

	# койот
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	# бафер на прыжок
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	#движение
	var direction := Input.get_axis("move_left", "move_right")

	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	# рывок
	if Input.is_action_just_pressed("dash"):
		if not is_dashing and dash_cooldown_timer == 0.0:
			perform_dash()
	if is_dashing:
		velocity = Vector2(dash_direction * dash_speed, 0.0)

		move_and_slide()
		dash_timer -= delta
		if dash_timer <= 0.0 or is_on_wall():
			finish_dash()

		_update_animation(direction)
		return

	if direction != 0.0:
		velocity.x = lerp(velocity.x,direction * move_speed * surface_speed_multiplier,20 * delta)
		facing_direction = 1 * sign(direction)
	else:
		velocity.x = lerp(velocity.x,0.0,20 * delta)

	# прыжок с койотом
	if jump_buffer_timer > 0.0:
		if is_on_floor() or coyote_timer > 0.0:
			perform_jump()

	# jump cut
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jumpcut_mult

	move_and_slide()
	# прыжок от баффера 
	if is_on_floor() and jump_buffer_timer > 0.0:
		perform_jump()

	check_spikes()
	_update_animation(direction)



func _update_animation(direction: float) -> void:
	# Определяем состояние
	var state: String
	
	if hurt_animation_timer > 0.0:
		return
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

	# расход баффера и койота
	coyote_timer = 0.0
	jump_buffer_timer = 0.0

	# Если кнопку отпустили до приземления,
	if not Input.is_action_pressed("jump"):
		velocity.y *= jumpcut_mult



func perform_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration

	#фиксируем направление на весь рывок
	dash_direction = facing_direction
	# рывок расходует возможность прыжка с койотом
	coyote_timer = 0.0
	velocity = Vector2(dash_direction * dash_speed , 0.0)



func finish_dash() -> void:
	is_dashing = false
	# перезарядка начинается после окончания рывка
	dash_cooldown_timer = dash_cooldown
	# убираем скорость
	velocity.x = 0.0



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

		# находим ячейку, с которой столкнулся персонаж
		var cell := tile_layer.get_coords_for_body_rid(collision.get_collider_rid())

		var tile_data := tile_layer.get_cell_tile_data(cell)

		if tile_data == null:
			continue

		var multiplier: float = tile_data.get_custom_data("speed_mult")

		if not surface_found:
			surface_speed_multiplier = multiplier
			surface_found = true
		else:
			# Если стоим сразу на нескольких поверхностях
			surface_speed_multiplier = minf(surface_speed_multiplier,multiplier)


func perform_dodge() -> void:
	is_dodging = true
	dodge_timer = dodge_duration

	velocity.x = -facing_direction * dodge_speed
	velocity.y = -dodge_jump_speed

	coyote_timer = 0.0
	jump_buffer_timer = 0.0

	sprite.flip_h = facing_direction < 0.0


func _process_dodge(delta: float) -> void:
	dodge_timer = maxf(dodge_timer - delta, 0.0)

	velocity += get_gravity() * delta

	velocity.x = move_toward(velocity.x,0.0,dodge_deceleration * delta)

	move_and_slide()

	if dodge_timer == 0.0 or is_on_floor():
		is_dodging = false
		dodge_cooldown_timer = dodge_cooldown


func check_spikes() -> void:
	if not can_take_damage:
		return
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
		
		if tile_layer.tile_set.get_custom_data_layer_by_name("damageontouch") == -1:
			continue
			
		var cell := tile_layer.get_coords_for_body_rid(collision.get_collider_rid())

		var tile_data := tile_layer.get_cell_tile_data(cell)

		if tile_data == null:
			continue

		var damage: int = tile_data.get_custom_data("damageontouch")

		if damage > 0:
			take_damage(damage)
			can_take_damage = false

			await get_tree().create_timer(spike_damage_cooldown).timeout

			can_take_damage = true

			return


func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	if health_bar:
		health_bar.value = health
	if sprite.sprite_frames.has_animation("take_damage"):
		hurt_animation_timer = 0.1
		sprite.play("take_damage")
	if health <= 0:
		queue_free()
