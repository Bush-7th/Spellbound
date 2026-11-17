class_name SignalOr extends RefCounted

var _triggered := false

signal triggered(idx: int)

func _init(...signals: Array) -> void:
	var idx := 0
	for s: Signal in signals:
		s.connect(_signal_triggered.bind(idx), ConnectFlags.CONNECT_ONE_SHOT)
		idx += 1

func _signal_triggered(idx: int) -> void:
	if _triggered:
		return
	_triggered = true
	triggered.emit(idx)
