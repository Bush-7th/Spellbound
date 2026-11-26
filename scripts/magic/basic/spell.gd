class_name Spell extends RefCounted

var _program: Array[Operation] = []
var _executions: Array[Execution] = []

## Authoring boundary for SpellBuilder. Runtime only sees operations and waits.
func compile_layers(layers: Array[SpellLayer]) -> void:
	var operations: Array[Operation] = []
	for layer in layers:
		for spell in layer.spells:
			operations.append(Operation.evaluate(spell))
		operations.append(Operation.wait_for_effects())
	_program = operations
	_program.make_read_only()

func eval(cast_ctx: CastContext) -> EvaluationStatus:
	assert(cast_ctx != null, "CastContext required")
	var execution := Execution.new(_program, cast_ctx.snapshot())
	_executions.append(execution)
	execution.finished.connect(_execution_finished.bind(execution), CONNECT_ONE_SHOT)
	execution.start()
	return execution.status

func _execution_finished(execution: Execution) -> void:
	assert(_executions.has(execution), "Only a registered execution can finish")
	_executions.erase(execution)

class SpellLayer extends RefCounted:
	var spells: Array[ElementarySpellHolder] = []

class Operation extends RefCounted:
	enum Kind { EVALUATE, WAIT }
	var kind: Kind
	var spell: ElementarySpellHolder

	static func evaluate(elementary_spell: ElementarySpellHolder) -> Operation:
		assert(elementary_spell != null, "ElementarySpellHolder required")
		var operation := Operation.new()
		operation.kind = Kind.EVALUATE
		operation.spell = elementary_spell
		return operation

	static func wait_for_effects() -> Operation:
		var operation := Operation.new()
		operation.kind = Kind.WAIT
		return operation

## Per-cast ownership and scheduling. BranchContext holds each execution cursor.
class Execution extends RefCounted:
	signal finished
	var status := EvaluationStatus.new()
	var _program: Array[Operation]
	var _context: CastContext
	var _active: Array[BranchContext] = []
	var _ready: Array[BranchContext] = []
	var _ready_index := 0
	# Branch -> { dependency: connected callback }. Disconnect on every exit path.
	var _subscriptions: Dictionary = {}
	var _scheduled := false
	var _failed := false

	func _init(program: Array[Operation], context: CastContext) -> void:
		_program = program
		_context = context


	func start() -> void:
		var caster := _context.caster
		if !is_instance_valid(caster) || !caster.is_inside_tree():
			_finish(true)
			return
		caster.tree_exiting.connect(_cancel, CONNECT_ONE_SHOT)
		var root := BranchContext.new(_context)
		_active.append(root)
		_ready.append(root)
		_drain()


	func _enqueue(branch: BranchContext) -> void:
		if status.has_completed:
			return
		assert(_active.has(branch), "Only active branches can be queued")
		# Processed entries stay in the array until the current drain finishes.
		if _ready.find(branch, _ready_index) == -1:
			_ready.append(branch)
		if !_scheduled:
			_scheduled = true
			_drain.call_deferred()


	func _drain() -> void:
		_scheduled = true
		while _ready_index < _ready.size() && !status.has_completed:
			var branch := _ready[_ready_index]
			_ready_index += 1
			assert(_active.has(branch), "Queued branches must be active")
			_run(branch)
		_ready.clear()
		_ready_index = 0
		_scheduled = false


	func _run(branch: BranchContext) -> void:
		assert(branch._cursor >= 0 && branch._cursor <= _program.size(), "Invalid instruction cursor")
		while branch._cursor < _program.size():
			var operation := _program[branch._cursor]
			if operation.kind == Operation.Kind.WAIT:
				if !_wait(branch):
					return
				branch._cursor += 1
			else:
				branch._cursor += 1
				var children := operation.spell.eval(branch)
				# Evaluation can synchronously remove the caster and cancel this cast.
				if status.has_completed:
					return
				if children.size() == 1 && children[0] == branch:
					continue
				_replace_branch(branch, children)
				return
		_retire(branch)


	func _replace_branch(parent: BranchContext, children: Array[BranchContext]) -> void:
		for child in children:
			assert(child != null && !_active.has(child), "A fork must return new, distinct branches")
			assert(child._cursor == parent._cursor, "Children must inherit the next instruction cursor")
			_active.append(child)
			_ready.append(child)
		_retire(parent)


	func _wait(branch: BranchContext) -> bool:
		if branch.has_pending_completions():
			_watch_completions(branch)
			return false
		_disconnect(branch)
		if branch.has_failed_completions():
			_failed = true
			_retire(branch)
			return false
		branch.apply_completion_results()
		return true


	func _watch_completions(branch: BranchContext) -> void:
		assert(!_subscriptions.has(branch), "A waiting branch must only be subscribed once")
		var connections: Dictionary = {}
		_subscriptions[branch] = connections
		for dependency in branch._pending:
			if !dependency.has_completed:
				# Each descendant needs a distinct listener on inherited handles.
				var callback := func(_failed_result: bool) -> void: _dependency_completed(branch)
				connections[dependency] = callback
				dependency.completed.connect(callback, CONNECT_ONE_SHOT)


	func _dependency_completed(branch: BranchContext) -> void:
		if !branch.has_pending_completions():
			_enqueue(branch)


	func _disconnect(branch: BranchContext) -> void:
		var connections: Dictionary = _subscriptions.get(branch, {})
		for dependency: EvaluationStatus in connections:
			var callback: Callable = connections[dependency]
			if dependency.completed.is_connected(callback):
				dependency.completed.disconnect(callback)
		_subscriptions.erase(branch)


	func _retire(branch: BranchContext) -> void:
		assert(_active.has(branch), "Only active branches can be retired")
		_disconnect(branch)
		_active.erase(branch)
		if _active.is_empty():
			_finish(_failed)


	func _cancel() -> void:
		_finish(true)


	func _finish(failed: bool) -> void:
		if status.has_completed:
			return
		for branch in _active:
			_disconnect(branch)
		_active.clear()
		_ready.clear()
		var caster := _context.caster
		if is_instance_valid(caster) && caster.tree_exiting.is_connected(_cancel):
			caster.tree_exiting.disconnect(_cancel)
		_context = null
		_program = []
		status.complete(failed)
		finished.emit()
