class_name ElementarySpellHolder extends RefCounted

var _script: Script

var _eval: Callable

func _init(script: Script) -> void:
	_script = script
	_eval = script.eval

func eval(ctx: BranchContext) -> Array[BranchContext]:
	return _eval.call(ctx)
