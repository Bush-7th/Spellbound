class_name FixedTarget extends Target

var _position: Vector2

func _init(target: Vector2) -> void:
	_position = target

func get_position() -> Vector2:
	return _position
