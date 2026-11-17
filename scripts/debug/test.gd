extends CharacterBody2D

var selector := NearestTargetSelector.new()
var out: Array[Target] = []
var placeholder: PackedFloat64Array

var spell := Spell.new()

var _facing_dir: Vector2
var _normal_speed: float = 100

func _init() -> void:
	#test_matrix()
	#test_matrix2()
	
	SpellRegister.register_all()
	placeholder.resize(SpellRegister.MagicSchool.SIZE)
	spell._layers = [Spell.SpellLayer.new()]
	spell._layers[0].spells.append(preload("res://scripts/magic/spells/waterball.gd").new())

func test_matrix() -> void:
	var m := Util.SymmetricBoolMatrix.new(6)
	print("Matrix:\n", m)
	print("Sum: ", m.sum_dim())
	for i in range(6):
		m.set_item(i, i, true)
		print("Matrix:\n", m)
		print("Sum: ", m.sum_dim(), "\n\n")

func test_matrix2() -> void:
	var m := Util.SymmetricBoolMatrix.new(6)
	for i in range(6):
		for j in range(6):
			m.set_item(i, j, true)
	print("Matrix:\n", m)
	print("Sum: ", m.sum_dim(), "\n\n")
	for i in range(3):
		m.reset(2 * i + 1)
		print("Matrix:\n", m)
		print("Sum: ", m.sum_dim(), "\n\n")

func _physics_process(delta: float) -> void:
	velocity.x = Input.get_axis(&'left', &'right')
	velocity.y = Input.get_axis(&'up', &'down')
	velocity = velocity.normalized() * (130.0 if Input.is_action_pressed("speed_up") else _normal_speed)
	move_and_slide()
	
	var real_velocity := get_real_velocity()
	if real_velocity.length() > 1:
		_facing_dir = real_velocity.normalized()
	if Input.is_action_just_pressed("trigger"):
		spell.eval(CastContext.new(
			self,
			_facing_dir * (_normal_speed + real_velocity.length()) / 2,
			self.global_position,
			10,
			placeholder
	))
