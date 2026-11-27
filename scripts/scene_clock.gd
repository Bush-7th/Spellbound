extends Node

var time: float = 0.0


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Обновляем часы раньше обычных физических обработчиков.
	process_physics_priority = -100


func _physics_process(delta: float) -> void:
	time += delta
