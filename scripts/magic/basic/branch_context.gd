class_name BranchContext extends RefCounted

## Mutable state for one execution line. cast_ctx is a shared, read-only snapshot.
var cast_ctx: CastContext
var anchor: Vector2
var impulse: Vector2
var subjects: Array[PhysicsBody2D] = []
var impact_multiplier := 1.0

var _targets: Array[Target] = []
var _targets_resolved := false
var targets: Array[Target]:
	get: return _targets
	set(value):
		_targets = value.duplicate()
		_targets_resolved = true

var _cursor := 0
var _pending: Array[EvaluationStatus] = []

func _init(context: CastContext) -> void:
	assert(context != null, "A branch requires a cast context")
	cast_ctx = context
	anchor = context.position
	impulse = context.impulse

func duplicate() -> BranchContext:
	var ctx := BranchContext.new(cast_ctx)
	ctx.anchor = anchor
	ctx.impulse = impulse
	ctx.subjects = subjects.duplicate()
	ctx._targets = _targets.duplicate()
	ctx._targets_resolved = _targets_resolved
	ctx.impact_multiplier = impact_multiplier
	ctx._cursor = _cursor
	ctx._pending = _pending.duplicate()
	return ctx

## Creates children at the next instruction; the executor starts them later.
func branch(data: Array, overrides: BranchOverrides = null) -> Array[BranchContext]:
	var children: Array[BranchContext] = []
	for item in data:
		var child := duplicate()
		child.impact_multiplier /= data.size()
		if overrides != null:
			if overrides.targets_override.is_valid():
				child.targets.assign(overrides.targets_override.call(item))
				child._targets_resolved = true
			if overrides.anchor_override.is_valid():
				child.anchor = overrides.anchor_override.call(item)
			if overrides.impulse_override.is_valid():
				child.impulse = overrides.impulse_override.call(item)
			if overrides.subjects_override.is_valid():
				child.subjects.assign(overrides.subjects_override.call(item))
			if overrides.completion_override.is_valid():
				child.add_completion(overrides.completion_override.call(item))
		children.append(child)
	return children

func add_completion(completion: EvaluationStatus) -> void:
	if completion != null && !_pending.has(completion):
		_pending.append(completion)

func has_pending_completions() -> bool:
	for completion in _pending:
		if !completion.has_completed:
			return true
	return false

func has_failed_completions() -> bool:
	for completion in _pending:
		if completion.has_failed:
			return true
	return false

func apply_completion_results() -> void:
	assert(!has_pending_completions(), "Completion results cannot be applied before the wait finishes")
	assert(!has_failed_completions(), "Failed completion results cannot advance a branch")
	# Registration order determines the final spatial result, regardless of hit order.
	for completion in _pending:
		if completion.result != null:
			anchor = completion.result.anchor
			impulse = completion.result.impulse
	_pending.clear()

func clear_targets() -> void:
	_targets = []
	_targets_resolved = false

func get_targets(default_selector: TargetSelector) -> Array[Target]:
	if !_targets_resolved:
		targets = default_selector.select(self)
	return targets

func get_target(default_selector: TargetSelector) -> Target:
	var selected := get_targets(default_selector)
	return selected.pick_random() if !selected.is_empty() else EmptyTarget.TARGET

func get_school_impact(magic_school: SpellRegister.MagicSchool) -> float:
	return cast_ctx.get_school_impact(magic_school) * impact_multiplier
