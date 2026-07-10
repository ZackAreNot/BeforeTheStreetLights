extends Node

const RUNNER_SCRIPT: Script = preload(
	"res://scenes/qa/transition_smoke_runner.gd"
)

func _ready() -> void:
	var runner: Node = Node.new()
	runner.set_script(RUNNER_SCRIPT)
	runner.name = "PersistentTransitionSmokeRunner"
	get_tree().root.add_child.call_deferred(runner)
	runner.call_deferred("run")
