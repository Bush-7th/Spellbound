class_name Character
extends CharacterBody2D

@export_category("Здоровье")
@export var max_health: int = 100

@export_category("Движение")
@export var move_speed: float = 260.0
@export var acceleration: float = 2200.0
@export var deceleration: float = 2800.0

@export_category("Прыжок")
@export var jump_speed: float = 440.0
