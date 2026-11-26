@abstract
class_name Modifier extends RefCounted

## SpellBuilder enforces these policies for each attribute's modifier chain.
enum Composition {
	CHAINABLE,
	FINAL,
	EXCLUSIVE,
}

## Concrete scripts provide static eval(ctx) -> void, attributes, and info.
## Hooks may mutate ctx, but must not branch or suspend. Attribute callbacks
## take (ctx, current_value), must only read ctx, and must not suspend.
class Info extends RefCounted:
	var _composition: Dictionary[SpellRegister.Attribute, Composition] = {}
	var composition: Dictionary[SpellRegister.Attribute, Composition]:
		get: return _composition

	func _init(rules: Dictionary[SpellRegister.Attribute, Composition] = {}) -> void:
		_composition = rules.duplicate()
		_composition.make_read_only()
