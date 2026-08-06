extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("3秒后跳转界面")
	await get_tree().create_timer(3.0).timeout
	SceneManager.change_scene("res://scene/node1.tscn")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
