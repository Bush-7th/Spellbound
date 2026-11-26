class_name SpellRegister extends RefCounted

static var _register: Array[Script] = []

static func register_all(path: String = "res://scripts/magic/spells") -> void:
	for file in DirAccess.open(path).get_files():
		if file.get_extension() == "gd":
			var spell: Script = ResourceLoader.load(path.path_join(file), "Script")
			# TODO: avoid new (?)
			_register.append(spell)
	_register.make_read_only()

class SpellInfo:
	var _school: MagicSchool
	#var _input
	#var _output
	
	func _init(school: MagicSchool) -> void:
		_school = school
	
	var school: MagicSchool:
		get: return _school
	
	#var input:
		#get: return _input
	
	#var output:
		#get: return _output

enum MagicSchool {
	ELEMENTAL,
	BLOOD,

	SIZE
}
