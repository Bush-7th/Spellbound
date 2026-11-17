class_name FreeSpaceSelector extends RefCounted

var _query_shape: Shape2D
var _query := PhysicsShapeQueryParameters2D.new()

var _region: Node2D

const _max_batch_size := 128

var selector_shape: Shape2D:
	get: return _query_shape
	set(val):
		_query_shape = val
		_query.shape_rid = _query_shape.get_rid()

var selector_transform: Transform2D:
	get: return _query.transform
	set(val): _query.transform = val

var region: Node2D:
	get: return _region
	set(val):
		if val is not CollisionShape2D && val is not CollisionPolygon2D:
			printerr("Incorrect region: %s" % [val])
		else:
			_region = val

func select_multiple(direct_space_state: PhysicsDirectSpaceState2D, count: int) -> Array[Vector2]:
	#TODO: update size (?)
	var candidates := _pick_random_points(_max_batch_size)
	candidates = candidates.filter(
		func(pnt: Vector2) -> bool:
			_query.transform.origin = pnt
			return direct_space_state.intersect_shape(_query, 1).size() == 0
	)
	if !candidates:
		return []
	
	var intersect_graph := Util.SymmetricBoolMatrix.new(candidates.size())
	var shape1 := CollisionShape2D.new()
	var shape2 := CollisionShape2D.new()
	shape1.shape = _query_shape
	shape2.shape = _query_shape
	for i in range(candidates.size()):
		shape1.transform.origin = candidates[i]
		for j in range(i + 1, candidates.size()):
			shape2.transform.origin = candidates[j]
			intersect_graph.set_item(i, j,
				Util.do_intersect(shape1, shape2)
			)
	
	var excluded: PackedByteArray
	var excluded_cnt := 0
	excluded.resize(candidates.size())
	var intersect_cnt := intersect_graph.sum_dim()
	while Util.count_zero(intersect_cnt) - excluded_cnt < count:
		var max_intersect_idx := Util.index_max_int32(intersect_cnt)
		if intersect_cnt[max_intersect_idx] == 0: break
		excluded[max_intersect_idx] = true
		excluded_cnt += 1
		intersect_graph.reset(max_intersect_idx)
		intersect_graph.sum_dim(intersect_cnt)
	
	var res: Array[Vector2]
	var candidate_idx := 0
	while res.size() < count && candidate_idx < candidates.size():
		if intersect_cnt[candidate_idx] == 0 && !excluded[candidate_idx]:
			res.append(candidates[candidate_idx])
		candidate_idx += 1
	
	return res

static func _estimate_batch_size(
	region_area: float,
	target_occupied_share: float,
	target_count: int,
	placing_object_area: float,
	target_success_probability: float
) -> int:
	var u := log(1 - pow(target_success_probability, 1.0 / target_count))
	var res := 0
	for i in range(target_count):
		res += ceili(u /
			log((target_occupied_share * region_area + i * placing_object_area) / region_area)
		)
	return res

func _pick_random_points(count: int = 1) -> Array[Vector2]:
	if _region is CollisionShape2D:
		if _region.shape is CircleShape2D:
			return _pick_random_points_circle(_region, count)
		if _region.shape is RectangleShape2D:
			return _pick_random_points_rect(_region, count)
	if _region is CollisionPolygon2D:
		return _pick_random_points_polygon(_region, count)
	
	printerr("Region shape is not set")
	return []


static var _prng := RandomNumberGenerator.new()

static func _pick_random_points_circle(shape: CollisionShape2D, count: int) -> Array[Vector2]:
	var res: Array[Vector2]
	res.resize(count)
	
	var circle := shape.shape as CircleShape2D
	for i in range(count):
		var angle := _prng.randf_range(0, TAU)
		var r := circle.radius * sqrt(_prng.randf())
		res[i] = shape.global_transform * Vector2(r * cos(angle), r * sin(angle))
	return res

static func _pick_random_points_rect(shape: CollisionShape2D, count: int) -> Array[Vector2]:
	var res: Array[Vector2]
	res.resize(count)
	
	var rect := shape.shape as RectangleShape2D
	for i in range(count):
		var local_pos := Vector2(
			_prng.randf_range(0, rect.size.x),
			_prng.randf_range(0, rect.size.y)
		)
		res[i] = shape.global_transform * local_pos
	return res

static func _pick_random_points_polygon(shape: CollisionPolygon2D, count: int) -> Array[Vector2]:
	var res: Array[Vector2]
	res.resize(count)
	
	var polygon := shape.polygon
	var triangulation := Geometry2D.triangulate_polygon(polygon)
	var areas: PackedFloat32Array
	areas.resize(triangulation.size() / 3)
	for i in range(areas.size()):
		areas[i] = Util.triangle_area(
			polygon[triangulation[3 * i]],
			polygon[triangulation[3 * i + 1]],
			polygon[triangulation[3 * i + 2]]
		)
	
	for i in range(count):
		var triangle_idx := _prng.rand_weighted(areas)
		
		var a := polygon[triangulation[triangle_idx * 3]]
		var b := polygon[triangulation[triangle_idx * 3 + 1]]
		var c := polygon[triangulation[triangle_idx * 3 + 2]]
		
		var u := _prng.randf()
		var v := _prng.randf()
		
		if u + v > 1:
			u = 1 - u
			v = 1 - v
		
		var local_point := a + u * (b - a) + v * (c - a)
		res[i] = shape.global_transform * local_point
	return res
