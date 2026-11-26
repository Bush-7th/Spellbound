class_name SignalAnd extends RefCounted

var _triggers_left: int

signal triggered

func _init(...signals: Array) -> void:
	_triggers_left = signals.size()
	for s: Signal in signals:
		s.connect(_signal_triggered, ConnectFlags.CONNECT_ONE_SHOT)

func _signal_triggered() -> void:
	_triggers_left -= 1
	if !_triggers_left:
		triggered.emit()
