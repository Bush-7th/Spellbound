class_name PlayerCharacter
extends Character

var surface_speed_multiplier: float = 1.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		surface_speed_multiplier = 1.0

	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0.0:
		velocity.x = move_toward(velocity.x , direction * move_speed * surface_speed_multiplier , acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x , 0.0 , deceleration * delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_speed

	move_and_slide()
