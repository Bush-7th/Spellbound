class_name NearestTargetSelector extends TargetSelector

var query_shape := CapsuleShape2D.new()
var query := PhysicsShapeQueryParameters2D.new()
 
func _init() -> void:
	query.shape_rid = query_shape.get_rid()
	query.collision_mask = 2

func select(ctx: BranchContext) -> Array[Target]:
	var caster := ctx.cast_ctx.caster
	if !is_instance_valid(caster) || !caster.is_inside_tree() || ctx.impulse.is_zero_approx():
		return []
	# TODO: handle radius
	query_shape.height = 2 * ctx.impulse.length()
	query_shape.radius = .3 * query_shape.height
	
	# TODO: handle friendly entities
	query.exclude = [caster.get_rid()]
	query.transform = Transform2D.IDENTITY.rotated(ctx.impulse.angle() + PI/2)
	query.transform.origin = ctx.anchor + ctx.impulse
	
	var intersections := caster.get_world_2d().direct_space_state.intersect_shape(query)

	var targets: Array[Target] = Array(intersections.map(
		func(dict: Dictionary):
			return FixedTarget.new((PhysicsServer2D.body_get_state(
				dict['rid'],
				PhysicsServer2D.BODY_STATE_TRANSFORM
			) as Transform2D).origin)
	), TYPE_OBJECT, &'RefCounted', preload("res://scripts/magic/basic/target.gd"))
	return targets
