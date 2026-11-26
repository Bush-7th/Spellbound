@abstract
extends RefCounted

const _waterball_scene := preload("res://scenes/projectiles/waterball.tscn")

static var _attributes: Dictionary[SpellRegister.Attribute, Callable] = {
	SpellRegister.Attribute.FORCE_SCALE: _default_force_scale,
}
static var attributes: Dictionary[SpellRegister.Attribute, Callable]:
	get: return _attributes

static func _static_init() -> void:
	_attributes.make_read_only()

static func _default_force_scale(_ctx: BranchContext, _current_value: Variant) -> float:
	return 200.0

static func eval(ctx: BranchContext, _impact: float, values: Dictionary[SpellRegister.Attribute, Variant]) -> Array[BranchContext]:
	var caster := ctx.cast_ctx.caster
	if !is_instance_valid(caster) || !caster.is_inside_tree():
		return []
	var region := CollisionShape2D.new()
	region.shape = CircleShape2D.new()
	region.shape.radius = 100
	region.global_position = ctx.anchor + ctx.impulse.normalized() * 100
	
	var selector := FreeSpaceSelector.new()
	selector.region = region
	selector.selector_shape = CircleShape2D.new()
	selector.selector_shape.radius = 20
	
	var waterballs: Array[WaterBall] = []
	var positions := selector.select_multiple(caster.get_world_2d().direct_space_state, 3)
	region.free()
	var parent_node := caster.get_node(^"%LiquidCanvas")
	var targets := ctx.get_targets(_get_default_target_selector())
	for position in positions:
		var target: Target = targets.pick_random() if !targets.is_empty() else FixedTarget.new(ctx.anchor + ctx.impulse * 100)
		waterballs.append(
			_summon_waterball(position, target, parent_node, values[SpellRegister.Attribute.FORCE_SCALE])
		)
	
	var overrides := BranchOverrides.new()
	overrides.subjects_override = func(ball: WaterBall) -> Array: return [ball]
	overrides.completion_override = func(ball: WaterBall) -> EvaluationStatus: return ball.completion_status
	var children := ctx.branch(waterballs, overrides)
	# All children have their completion handles before effects can start.
	for waterball in waterballs:
		waterball.eval()
	return children

static func _summon_waterball(pos: Vector2, target: Target, parent_node: Node, force_scale: float) -> WaterBall:
	var waterball: WaterBall = _waterball_scene.instantiate()
	waterball.target = target
	waterball.force_scale = force_scale
	parent_node.add_child(waterball)
	waterball.global_position = pos
	waterball.reset_physics_interpolation()
	return waterball

static var _info: SpellRegister.SpellInfo = (
	SpellRegister.SpellInfo.new(
		SpellRegister.MagicSchool.ELEMENTAL
))
static var info:
	get: return _info

static func _get_default_target_selector() -> TargetSelector:
	return NearestTargetSelector.new()
