class_name BranchOverrides extends RefCounted

## Each callback receives one item from branch(data). An empty Callable inherits.
var targets_override: Callable
var anchor_override: Callable
var impulse_override: Callable
var subjects_override: Callable
## Adds one EvaluationStatus to the child's inherited dependencies.
var completion_override: Callable
