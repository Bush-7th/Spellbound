class_name CastContext extends RefCounted

var caster: PhysicsBody2D
var position: Vector2
var impulse: Vector2
var _impact_amount: float
## Original cast input; execution spends BranchContext.remaining_impact instead.
var impact: float:
	get: return _impact_amount

@warning_ignore("shadowed_variable")
func init(caster: PhysicsBody2D, position: Vector2, impulse: Vector2, impact: float) -> void:
	assert(is_finite(impact) && impact >= 0, "Cast impact must be finite and nonnegative")
	self.caster = caster
	self._impact_amount = impact
	self.position = position
	self.impulse = impulse

func reset() -> void:
	caster = null
	position = Vector2.ZERO
	impulse = Vector2.ZERO
	_impact_amount = 0

## Callers may reuse their input context; active casts own this independent copy.
func snapshot() -> CastContext:
	var context := CastContext.new()
	context.init(caster, position, impulse, _impact_amount)
	return context
