class_name ElementarySpellHolder extends RefCounted

var _script: Script

var _eval: Callable
var _attributes: Dictionary[SpellRegister.Attribute, Callable] = {}
var _modifiers: Array[ModifierHolder] = []

## Configuration is captured once. SpellBuilder owns compatibility and ordering.
func _init(script: Script, modifiers: Array[ModifierHolder] = []) -> void:
	assert(script != null, "Spell script required")
	_script = script
	_eval = script.eval
	_attributes = script.attributes
	_modifiers = modifiers.duplicate()
	_modifiers.make_read_only()

func eval(ctx: BranchContext, allocate_impact: Callable) -> Array[BranchContext]:
	assert(allocate_impact.is_valid(), "Impact allocator required")
	for modifier in _modifiers:
		modifier.eval(ctx)
	var values := _resolve_attributes(ctx)
	var impact: float = allocate_impact.call()
	return _eval.call(ctx, impact, values)

func _resolve_attributes(ctx: BranchContext) -> Dictionary[SpellRegister.Attribute, Variant]:
	var values: Dictionary[SpellRegister.Attribute, Variant] = {}
	for attribute in _attributes:
		values[attribute] = _attributes[attribute].call(ctx, null)
	for modifier in _modifiers:
		for attribute in modifier.attributes:
			values[attribute] = modifier.attributes[attribute].call(ctx, values[attribute])
	values.make_read_only()
	return values
