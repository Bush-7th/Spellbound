@tool
extends BTAction

var _triggered: bool

@export var node_path: BBNode
@export var signal_name: StringName

func _setup() -> void:
	var node := agent.get_node(node_path.saved_value)
	node.connect(signal_name, func(): _triggered = true)

func _enter() -> void:
	_triggered = false

func _tick(_delta: float) -> Status:
	return Status.SUCCESS if _triggered else Status.RUNNING

func _generate_name() -> String:
	return "Await %s on %s" % [signal_name, node_path]
