class_name CastContext extends RefCounted

var caster: PhysicsBody2D
var position: Vector2
var impulse: Vector2
var _impact_amount: float
var _impact_distribution: PackedFloat64Array

@warning_ignore("shadowed_variable")
func init(caster: PhysicsBody2D, position: Vector2, impulse: Vector2, impact: float, impact_distribution: PackedFloat64Array) -> void:
	assert(impact_distribution.size() == SpellRegister.MagicSchool.SIZE, "Impact distribution must contain one entry per magic school")
	self.caster = caster
	self._impact_amount = impact
	self.position = position
	self.impulse = impulse

	# TODO: check for impact modifiers
	self._impact_distribution = impact_distribution.duplicate()

func reset() -> void:
	caster = null
	position = Vector2.ZERO
	impulse = Vector2.ZERO
	_impact_amount = 0
	_impact_distribution = []

## Callers may reuse their input context; active casts own this independent copy.
func snapshot() -> CastContext:
	var context := CastContext.new()
	context.init(caster, position, impulse, _impact_amount, _impact_distribution)
	return context


func get_school_impact(magic_school) -> float:
	return _impact_distribution[magic_school] * _impact_amount
