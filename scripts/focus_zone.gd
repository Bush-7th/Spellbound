@tool
extends Area2D

@export var camera: GameCamera:
	set(value):
		camera = value
		update_configuration_warnings()

@export var focus_target: Node2D:
	set(value):
		focus_target = value
		update_configuration_warnings()

@export_range(0.0, 1.0, 0.05) var focus_weight: float = 1.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if camera == null:
		warnings.append("Не назначено поле Camera")

	if focus_target == null:
		warnings.append("Не назначено поле Focus Target")

	return warnings


func _on_body_entered(body: Node2D) -> void:
	if _is_valid_player(body):
		camera.set_focus(focus_target, focus_weight)


func _on_body_exited(body: Node2D) -> void:
	if _is_valid_player(body):
		# Передаём свой focus_target, чтобы пересекающиеся зоны
		# не сбрасывали фокус друг друга.
		camera.clear_focus(focus_target)


func _is_valid_player(body: Node2D) -> bool:
	return (
		is_instance_valid(camera)
		and is_instance_valid(focus_target)
		and body == camera.player
	)
