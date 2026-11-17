class_name Spell extends RefCounted

var _layers: Array[SpellLayer]
var _default_impact_distribution: PackedFloat64Array

func eval(cast_ctx: CastContext):
	cast_ctx._impact_distribution = _compute_impact_distribution(cast_ctx)
	for layer in _layers:
		var layer_ctx := LayerContext.new()
		for spell in layer.spells:
			spell.eval(cast_ctx, layer_ctx)

func _compute_impact_distribution(cast_ctx: CastContext) -> PackedFloat64Array:
	# TODO: handle area effects
	return _default_impact_distribution.duplicate()

class SpellLayer:
	var spells: Array[ElementarySpell]
