extends CharacterBody2D

var selector := NearestTargetSelector.new()
var out: Array[Target] = []
var placeholder: PackedFloat64Array

var spell := Spell.new()

var _facing_dir: Vector2
var _normal_speed: float = 100

func _init() -> void:
	SpellRegister.register_all()
	placeholder.resize(SpellRegister.MagicSchool.SIZE)
	placeholder[SpellRegister.MagicSchool.ELEMENTAL] = 1.0
	var layer := Spell.SpellLayer.new()
	layer.spells.append(
		ElementarySpellHolder.new(preload("res://scripts/magic/spells/waterball.gd")
	))
	spell.compile_layers([layer])

var _cast_ctx := CastContext.new()
func _physics_process(delta: float) -> void:
	velocity.x = Input.get_axis(&'left', &'right')
	velocity.y = Input.get_axis(&'up', &'down')
	velocity = velocity.normalized() * (130.0 if Input.is_action_pressed("speed_up") else _normal_speed)
	move_and_slide()
	
	var real_velocity := get_real_velocity()
	if real_velocity.length() > 1:
		_facing_dir = real_velocity.normalized()
	if Input.is_action_just_pressed("trigger"):
		_cast_ctx.init(
			self,
			self.global_position,
			_facing_dir * (_normal_speed + real_velocity.length()) / 2,
			10,
			placeholder
		)
		spell.eval(_cast_ctx)
		_cast_ctx.reset()
