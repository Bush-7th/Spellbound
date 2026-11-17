extends ElementarySpell

var _waterball_scene := preload("res://scenes/projectiles/waterball.tscn")

func eval(cast_ctx: CastContext, layer_ctx: LayerContext):
	var region := CollisionShape2D.new()
	region.shape = CircleShape2D.new()
	region.shape.radius = 100
	region.global_position = cast_ctx.caster.global_position + cast_ctx.impulse.normalized() * 100
	
	var selector := FreeSpaceSelector.new()
	selector.region = region
	selector.selector_shape = CircleShape2D.new()
	selector.selector_shape.radius = 20
	
	var pos = selector.select_multiple(cast_ctx.caster.get_world_2d().direct_space_state, 3)
	print(pos, ' ', cast_ctx.caster.global_position)
	#waterball.position = cast_ctx.anchor + cast_ctx.impulse * .5
	#waterball.target = get_target(cast_ctx, layer_ctx)
	var parent_node := cast_ctx.caster.get_node(^"%LiquidCanvas")
	for i in range(pos.size()):
		_summon_waterball(pos[i], get_target(cast_ctx, layer_ctx), parent_node)

func _summon_waterball(pos: Vector2, target: Target, parent_node: Node) -> void:
	var waterball: WaterBall = _waterball_scene.instantiate()
	waterball.global_position = pos
	waterball.target = target
	parent_node.add_child(waterball)
	waterball.eval()

func _get_info() -> SpellRegister.SpellInfo:
	return SpellRegister.SpellInfo.new(
		SpellRegister.MagicSchool.ELEMENTAL
	)

func _get_default_target_selector() -> TargetSelector:
	return NearestTargetSelector.new()
