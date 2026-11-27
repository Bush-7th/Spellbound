class_name InputBuffer
extends RefCounted

var _actions: Array[StringName] = []
var _pressed_at: Dictionary = {}


func _init(actions: Array[StringName]) -> void:
	_actions.assign(actions)


func update(current_time: float) -> void:
	for action in _actions:
		if Input.is_action_just_pressed(action):
			_pressed_at[action] = current_time


func has_action(
	action: StringName,
	max_age: float,
	current_time: float
) -> bool:
	if not _pressed_at.has(action):
		return false

	var pressed_time: float = _pressed_at[action]
	var age := current_time - pressed_time

	return age >= 0.0 and age <= max_age


func consume(
	action: StringName,
	max_age: float,
	current_time: float
) -> bool:
	if not has_action(action, max_age, current_time):
		return false

	clear_action(action)
	return true


func clear_action(action: StringName) -> void:
	_pressed_at.erase(action)
