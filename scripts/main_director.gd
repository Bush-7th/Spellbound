@tool
class_name CameraDirector
extends Node2D

@export var bounds: Rect2 = Rect2(
	Vector2(-500.0, -500.0),
	Vector2(1600.0, 1000.0)
):
	set(value):
		bounds = value
		queue_redraw()

@export var editor_color: Color = Color(0.2, 0.8, 1.0, 0.8):
	set(value):
		editor_color = value
		queue_redraw()


func get_world_bounds() -> Rect2:
	var corner_a := to_global(bounds.position)
	var corner_b := to_global(bounds.end)

	var top_left := Vector2(
		minf(corner_a.x, corner_b.x),
		minf(corner_a.y, corner_b.y)
	)

	var bottom_right := Vector2(
		maxf(corner_a.x, corner_b.x),
		maxf(corner_a.y, corner_b.y)
	)

	return Rect2(top_left, bottom_right - top_left)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	draw_rect(bounds, editor_color, false, 3.0)
