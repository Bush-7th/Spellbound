@abstract
class_name ElementarySpell extends RefCounted

var _register_id: int

var registry_info: SpellRegister.SpellInfo:
	get: return SpellRegister.spell_info(_register_id)

@abstract func eval(cast_ctx: CastContext, layer_ctx: LayerContext)
@abstract func _get_default_target_selector() -> TargetSelector
@abstract func _get_info() -> SpellRegister.SpellInfo

func get_info(register_id: int) -> SpellRegister.SpellInfo:
	_register_id = register_id
	return _get_info()

func get_target(cast_ctx: CastContext, layer_ctx: LayerContext) -> Target:
	if !layer_ctx.targets.is_empty():
		return layer_ctx.targets.pick_random()
	
	var targets := _get_default_target_selector().select(cast_ctx)
	if !targets.is_empty():
		return targets.pick_random()
	
	return FixedTarget.new(cast_ctx.anchor + cast_ctx.impulse * 100)
