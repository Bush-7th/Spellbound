class_name CastContext extends RefCounted

var caster: PhysicsBody2D
var impulse: Vector2
var anchor: Vector2
var _impact_amount: float
var _impact_distribution: PackedFloat64Array

@warning_ignore("shadowed_variable")
func _init(caster: PhysicsBody2D, impulse: Vector2, anchor: Vector2, impact: float, impact_distribution: PackedFloat64Array) -> void:
	self.caster = caster
	self.impulse = impulse
	self.anchor = anchor
	self._impact_amount = impact

	# TODO: check for impact modifiers
	self._impact_distribution = impact_distribution

	if impact_distribution.size() != SpellRegister.MagicSchool.SIZE:
		printerr("Incorrect impact_distribution")


func get_school_impact(magic_school) -> float:
	return _impact_distribution[magic_school] * _impact_amount
