class_name SpellRegister extends RefCounted

static var _register: Array[SpellInfo] = []

static func register_all(path: String = "res://scripts/magic/spells") -> void:
	for file in DirAccess.open(path).get_files():
		if file.get_extension() == "gd":
			var spell: Script = ResourceLoader.load(path.path_join(file), "Script")
			# TODO: avoid new (?)
			_register.append(spell.new().call("get_info", _register.size()))
	_register.make_read_only()

static func spell_info(id: int) -> SpellInfo:
	return _register[id]

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
