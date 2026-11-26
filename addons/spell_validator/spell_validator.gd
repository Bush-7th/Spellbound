@tool
extends EditorPlugin

const SPELL_DIR := "res://scripts/magic/spells"

func _enter_tree() -> void:
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_validate_all)
	_validate_all.call_deferred()

func _exit_tree() -> void:
	EditorInterface.get_resource_filesystem().filesystem_changed.disconnect(_validate_all)

func _build() -> bool:
	return _validate_all()


func _validate_all() -> bool:
	var spell_dir := EditorInterface.get_resource_filesystem().get_filesystem_path(SPELL_DIR)
	if spell_dir == null:
		return true
	var res := true
	for i in range(spell_dir.get_file_count()):
		var spell_path := spell_dir.get_file_path(i)
		if spell_path.get_extension() != "gd":
			push_warning("Unexpected file in spells directory: %s (expected a .gd spell script)" % spell_path)
			continue
		var spell: Script = ResourceLoader.load(spell_path, "Script", ResourceLoader.CACHE_MODE_IGNORE)
		var valid := _validate_spell(spell)
		res = valid && res
	return res

func _validate_spell(spell: Script) -> bool:
	if spell == null:
		push_error("Could not load spell script")
		return false
	var errors := validation_errors(spell)
	for message in errors:
		push_error("%s: %s" % [spell.resource_path, message])
	return errors.is_empty()

static func validation_errors(spell: Script) -> PackedStringArray:
	var errors := PackedStringArray()
	
	if !spell.is_abstract():
		errors.append("Spell must be abstract")
	
	var method_list := spell.get_script_method_list()
	var idx := method_list.find_custom(func(f: Dictionary) -> bool: return f.name == "eval")
	if idx == -1:
		errors.append("Missing eval")
		return errors
	
	var method := method_list[idx]
	
	if !(method.flags & MethodFlags.METHOD_FLAG_STATIC):
		errors.append("Eval must be static")
	
	if method.args.size() != 1 || !method.default_args.is_empty() || (method.flags & METHOD_FLAG_VARARG):
		errors.append("Eval must take exactly one required BranchContext")
	else:
		if method.args[0]['class_name'] != "BranchContext":
			errors.append("Eval argument must be BranchContext")
	var result: Dictionary = method['return']
	if result.type != TYPE_ARRAY || result.hint != PROPERTY_HINT_ARRAY_TYPE || result.hint_string != "BranchContext":
		errors.append("Eval must return Array[BranchContext]")
	return errors
