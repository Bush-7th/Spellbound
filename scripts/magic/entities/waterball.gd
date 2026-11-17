class_name WaterBall extends RigidBody2D

@onready var _hsm: LimboHSM = $HSM
@onready var _visual: Polygon2D = $Visual
@onready var _collider: CollisionShape2D = $Collider
@onready var _particles_create: GPUParticles2D = $Create
@onready var _particles_destroy: GPUParticles2D = $Destroy
@onready var _timer: Timer = $Timer

signal collided

var target: Target
var force_scale: float = 200
@export var follow_time_limit: float = 1
@export var existence_time_limit: float = 1#.05

var _radius: int = 10
var radius: int:
	get:
		return _radius
	set(val):
		_radius = val
		_collider.shape.radius = val
		_update_visual()

const _polygon_edge_length: float = 4
var size_el: float = .2

func _ready() -> void:
	_init_state_machine()
	# Updates collider and visuals
	radius = radius

func _init_state_machine() -> void:
	var creation_state := LimboState.new().named("Creation") \
		.call_on_enter(_create).call_on_update(_process_creation)
	var follow_state := LimboState.new().named("Follow") \
		.call_on_enter(_start_follow).call_on_update(_process_follow_existence)
	var existence_state := LimboState.new().named("Existence") \
		.call_on_enter(_start_existence).call_on_update(_process_follow_existence)
	var destruction_state := LimboState.new().named("Destruction") \
		.call_on_enter(_destroy)
	
	_hsm.add_child(creation_state)
	_hsm.add_child(follow_state)
	_hsm.add_child(existence_state)
	_hsm.add_child(destruction_state)
	
	_hsm.add_transition(creation_state, follow_state, &"created")
	_hsm.add_transition(follow_state, existence_state, &"follow_timeout")
	_hsm.add_transition(follow_state, destruction_state, &"destroy")
	_hsm.add_transition(existence_state, destruction_state, &"destroy")
	
	collided.connect(func(): _hsm.dispatch(&"destroy"))
	
	_hsm.initialize(self)

func eval() -> void:
	_hsm.set_active(true)
	_hsm.restart()
	set_process(true)

func _start_follow() -> void:
	gravity_scale = 0
	freeze = false
	
	_timer.start(follow_time_limit)
	_timer.timeout.connect(
		func(): _hsm.dispatch(&"follow_timeout"),
		ConnectFlags.CONNECT_ONE_SHOT
	)

func _start_existence() -> void:
	gravity_scale = 1
	
	_timer.start(existence_time_limit)
	_timer.timeout.connect(
		func(): _hsm.dispatch(&"destroy"),
		ConnectFlags.CONNECT_ONE_SHOT
	)

func _create() -> void:
	freeze = true
	_visual.scale = Vector2.ONE / 1000
	
	_particles_create.restart()
	_timer.start(_particles_create.lifetime)
	_timer.timeout.connect(
		func(): _hsm.dispatch(&"created"),
		ConnectFlags.CONNECT_ONE_SHOT
	)

func _process_creation(_delta: float) -> void:
	_visual.scale = Vector2.ONE * (_timer.wait_time - _timer.time_left) / _timer.wait_time

func _process_follow_existence(_delta: float) -> void:
	_visual.scale.x = 1 + clampf(linear_velocity.length(), 0, size_el)
	_visual.rotation = linear_velocity.angle()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	state.apply_central_force(global_position.direction_to(target.get_position()) * force_scale)

func _physics_process(_delta: float) -> void:
	if get_colliding_bodies().size() > 0:
		gravity_scale = 1
		collided.emit()

func _update_visual() -> void:
	var point_count := roundi(TAU * _radius / _polygon_edge_length)
	var points := PackedVector2Array()
	points.resize(point_count)
	for i in range(0, point_count):
		var angle := TAU * i / point_count
		points[i].x = cos(angle) * _radius
		points[i].y = sin(angle) * _radius
	
	_visual.polygon = points

func _destroy() -> void:
	_visual.hide()
	collision_layer = 0
	collision_mask = 0
	freeze = true
	_particles_destroy.rotation = (
		linear_velocity.rotated(PI).angle()
		if _hsm.get_previous_active_state().name == &"Follow" else 
		lerp_angle(linear_velocity.angle(), get_gravity().angle(), 0.3)
	)
	_particles_destroy.reset_physics_interpolation()
	_particles_destroy.restart()
	await _particles_destroy.finished
	
	# TODO: object pooling (?; benchmark)
	queue_free()
