extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.on("test", test)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func test() -> void:
	print("EventBus测试通过")
