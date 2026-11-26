class_name EvaluationStatus extends RefCounted

## A one-shot completion that remains observable after its signal was emitted.
signal completed(failed: bool)

var _completed := false
var _failed := false
var _result: SpatialResult

var has_completed: bool:
	get: return _completed
var has_failed: bool:
	get: return _failed
var result: SpatialResult:
	get: return _result

func complete(failed: bool = false, spatial_result: SpatialResult = null) -> void:
	if _completed:
		return
	_failed = failed
	_result = spatial_result
	_completed = true
	completed.emit(_failed)

func wait() -> EvaluationStatus:
	if !has_completed:
		await completed
	return self

class SpatialResult extends RefCounted:
	var anchor: Vector2
	var impulse: Vector2

	func _init(hit_position: Vector2, hit_velocity: Vector2) -> void:
		anchor = hit_position
		impulse = hit_velocity
