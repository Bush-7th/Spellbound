class_name Util extends RefCounted

static func triangle_area(a: Vector2, b: Vector2, c: Vector2) -> float:
	return abs((b - a).cross(c - a)) / 2

static func do_intersect(a: CollisionShape2D, b: CollisionShape2D) -> bool:
	return a.shape.collide(a.global_transform, b.shape, b.global_transform)

static func index_max_int32(arr: PackedInt32Array) -> int:
	var max := arr[0]
	var max_idx := 0
	var cur := 0
	for val in arr:
		if val > max:
			max_idx = cur
			max = val
		cur += 1
	return max_idx

static func count_zero(arr: PackedInt32Array) -> int:
	var cnt := 0
	for val in arr:
		cnt += int(val == 0)
	return cnt

class SymmetricBoolMatrix:
	var _data: PackedByteArray
	var _n: int
	
	func _idx(i: int, j: int) -> int:
		assert(i >= 0 && i < _n)
		assert(j >= 0 && j < _n)
		if i > j:
			j ^= i
			i ^= j
			j ^= i
		return (2 * _n - i - 1) * i / 2 + j
	
	func _init(n: int) -> void:
		_n = n
		_data.resize(n * (n + 1) / 2)
	
	func get_item(i: int, j: int) -> bool:
		return _data[_idx(i, j)]
	
	func set_item(i: int, j: int, val: bool) -> void:
		_data[_idx(i, j)] = int(val)
	
	func reset(idx: int) -> void:
		var diag_idx := _idx(idx, idx)
		var cur := _idx(0, idx)
		for i in range(idx):
			_data[cur] = false
			cur += _n - i - 1
		for i in range(diag_idx, _idx(idx, _n - 1) + 1):
			_data[i] = false
	
	func sum_dim(out: PackedInt32Array = []) -> PackedInt32Array:
		out.resize(_n)
		out.fill(0)
		var data_idx := 0
		for i in range(_n):
			for j in range(i, _n):
				out[i] += _data[data_idx]
				out[j] += _data[data_idx]
				out[i] -= int(i == j) * _data[data_idx]
				data_idx += 1
		return out
	
	func _to_string() -> String:
		if !OS.is_debug_build():
			print("Printing matrices is not recommended for release builds")
		var s := ""
		for i in range(_n):
			for j in range(_n):
				s += str(int(get_item(i, j))) + " "
			s += "\n"
		return s
