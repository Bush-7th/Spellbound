extends CanvasLayer

@export var player: PlayerCharacter
@export var health_bar: ProgressBar
@export var stamina_bar: ProgressBar


func _ready() -> void:
	if is_instance_valid(player):
		player.health_changed.connect(_on_health_changed)
		player.stamina_changed.connect(_on_stamina_changed)


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current
