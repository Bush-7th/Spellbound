@abstract
extends Modifier

static var _attributes: Dictionary[SpellRegister.Attribute, Callable] = {}
static var attributes: Dictionary[SpellRegister.Attribute, Callable]:
	get: return _attributes

static var _info := Modifier.Info.new()
static var info: Modifier.Info:
	get: return _info

static func _static_init() -> void:
	_attributes.make_read_only()

static func eval(ctx: BranchContext) -> void:
	ctx.clear_targets()
