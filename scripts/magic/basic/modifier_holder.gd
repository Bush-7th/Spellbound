class_name ModifierHolder extends RefCounted

var _script: Script
var _eval: Callable
var _attributes: Dictionary[SpellRegister.Attribute, Callable] = {}
var _info: Modifier.Info

var attributes: Dictionary[SpellRegister.Attribute, Callable]:
	get: return _attributes
var info: Modifier.Info:
	get: return _info

## The builder supplies valid scripts; construction captures their definitions.
func _init(script: Script) -> void:
	assert(script != null, "Modifier script required")
	_script = script
	_eval = script.eval
	_attributes = script.attributes
	_info = script.info

func eval(ctx: BranchContext) -> void:
	_eval.call(ctx)
