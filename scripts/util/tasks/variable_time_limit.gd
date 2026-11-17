@tool
extends BTDecorator
#TODO: rewrite using timestamps

@export var limit: BBFloat

var _timer: SceneTreeTimer
var _triggered: bool

func _enter() -> void:
	var time: float = limit.get_value(agent.get_tree().root, blackboard)
	_timer = agent.get_tree().create_timer(time)
	_triggered = false
	_timer.timeout.connect(func(): _triggered = true)

func _exit() -> void:
	if !_triggered && is_instance_valid(_timer):
		for m in _timer.timeout.get_connections():
			_timer.timeout.disconnect(m.callable)

func _tick(delta: float) -> Status:
	if !_triggered:
		return get_child(0).execute(delta)
	else:
		get_child(0).abort()
		return Status.FAILURE

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if get_child_count() != 1:
		warnings.append("Must have exactly 1 child")
	return warnings

func _generate_name() -> String:
	return "Limit by %s" % [limit.variable] 
