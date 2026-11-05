class_name PlayerCamera
extends Camera2D

@export var look_ahead_distance: float = 60.0
@export var look_ahead_speed: float = 6.0

@export var vertical_look_distance: float = 50.0
@export var vertical_look_speed: float = 3.0

var target_offset := Vector2.ZERO
var current_offset := Vector2.ZERO


func _physics_process(delta: float) -> void:
	var player := get_parent() as PlayerCharacter

	if player == null:
		return

	var direction := Input.get_axis("move_left", "move_right")

	# Горизонтальный look-ahead
	var horizontal_target := direction * look_ahead_distance

	# Вертикальный look-ahead
	var vertical_target := 0.0

	if not player.is_on_floor():
		if player.velocity.y < 0.0:
			vertical_target = -vertical_look_distance * 0.5
		else:
			vertical_target = vertical_look_distance

	target_offset = Vector2(horizontal_target, vertical_target)

	current_offset = current_offset.lerp(target_offset,1.0 - exp(-look_ahead_speed * delta))

	offset = current_offset
