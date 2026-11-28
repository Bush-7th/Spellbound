class_name DamageZone
extends Area2D

@export var damage: int = 10

func _physics_process(delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is PlayerCharacter:
			body.take_damage(damage)
