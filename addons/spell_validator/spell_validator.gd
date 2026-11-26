@tool
extends EditorPlugin

const SPELL_DIR := "res://scripts/magic/spells"
const MODIFIER_DIR := "res://scripts/magic/modifiers"

func _enter_tree() -> void:
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_validate_all)
	_validate_all.call_deferred()

func _exit_tree() -> void:
	EditorInterface.get_resource_filesystem().filesystem_changed.disconnect(_validate_all)

func _build() -> bool:
	return _validate_all()


func _validate_all() -> bool:
	var spells_valid := _validate_directory(SPELL_DIR, _validate_spell)
	var modifiers_valid := _validate_directory(MODIFIER_DIR, _validate_modifier)
	return spells_valid && modifiers_valid

func _validate_directory(path: String, validate: Callable) -> bool:
	var directory := EditorInterface.get_resource_filesystem().get_filesystem_path(path)
	if directory == null:
		return true
	var res := true
	for i in range(directory.get_file_count()):
		var script_path := directory.get_file_path(i)
		if script_path.get_extension() != "gd":
			push_warning("Unexpected file in %s: %s (expected a .gd script)" % [path, script_path])
			continue
		var script: Script = ResourceLoader.load(script_path, "Script", ResourceLoader.CACHE_MODE_IGNORE)
		var valid: bool = validate.call(script)
		res = valid && res
	return res

func _validate_spell(spell: Script) -> bool:
	if spell == null:
		push_error("Could not load spell script")
		return false
	return _report_validation_errors(spell, validation_errors(spell))

func _validate_modifier(modifier: Script) -> bool:
	if modifier == null:
		push_error("Could not load modifier script")
		return false
	return _report_validation_errors(modifier, modifier_validation_errors(modifier))

func _report_validation_errors(script: Script, errors: PackedStringArray) -> bool:
	for message in errors:
		push_error("%s: %s" % [script.resource_path, message])
	return errors.is_empty()

static func validation_errors(spell: Script) -> PackedStringArray:
	var errors := PackedStringArray()
	var method := _evaluation_method(spell, errors)
	if method.is_empty():
		return errors
	if _validate_argument_count(method, 3, errors):
		if method.args[0]['class_name'] != "BranchContext":
			errors.append("Eval first argument must be BranchContext")
		if method.args[1].type != TYPE_FLOAT:
			errors.append("Eval second argument must be float impact")
		var values: Dictionary = method.args[2]
		if values.type != TYPE_DICTIONARY || values.hint != PROPERTY_HINT_DICTIONARY_TYPE || values.hint_string != "SpellRegister.Attribute;Variant":
			errors.append("Eval third argument must be Dictionary[SpellRegister.Attribute, Variant]")
	var result: Dictionary = method['return']
	if result.type != TYPE_ARRAY || result.hint != PROPERTY_HINT_ARRAY_TYPE || result.hint_string != "BranchContext":
		errors.append("Eval must return Array[BranchContext]")
	return errors

static func modifier_validation_errors(modifier: Script) -> PackedStringArray:
	var errors := PackedStringArray()
	var method := _evaluation_method(modifier, errors)
	if method.is_empty():
		return errors
	if _validate_argument_count(method, 1, errors):
		if method.args[0]['class_name'] != "BranchContext":
			errors.append("Modifier eval argument must be BranchContext")
	var result: Dictionary = method['return']
	if result.type != TYPE_NIL || (result.usage & PROPERTY_USAGE_NIL_IS_VARIANT):
		errors.append("Modifier eval must return void")
	return errors

static func _evaluation_method(script: Script, errors: PackedStringArray) -> Dictionary:
	if !script.is_abstract():
		errors.append("Script must be abstract")
	var method_list := script.get_script_method_list()
	var idx := method_list.find_custom(func(f: Dictionary) -> bool: return f.name == "eval")
	if idx == -1:
		errors.append("Missing eval")
		return {}
	
	var method := method_list[idx]
	
	if !(method.flags & MethodFlags.METHOD_FLAG_STATIC):
		errors.append("Eval must be static")
	return method

static func _validate_argument_count(method: Dictionary, count: int, errors: PackedStringArray) -> bool:
	if method.args.size() != count || !method.default_args.is_empty() || (method.flags & METHOD_FLAG_VARARG):
		errors.append("Eval must take exactly %d required arguments" % count)
		return false
	return true
