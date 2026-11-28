extends Area2D

@export var camera: GameCamera
@export var director: CameraDirector
@export var priorit: int = 10


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not is_instance_valid(camera):
		return

	if body != camera.player:
		return

	if not is_instance_valid(director):
		push_warning("CameraDirectorZone: не назначен директор")
		return

	camera.enter_director_zone(self, director, priorit)


func _on_body_exited(body: Node2D) -> void:
	if not is_instance_valid(camera):
		return

	if body != camera.player:
		return

	camera.exit_director_zone(self)


func _exit_tree() -> void:
	if is_instance_valid(camera):
		camera.exit_director_zone(self)
