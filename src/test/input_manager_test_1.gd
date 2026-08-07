extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#InputManager.is_action_just_pressed("up")
	#if InputManager.is_action_just_released("down"):
		#print("down")
	#if InputManager.get_move_vector():
		#print(InputManager.get_move_vector())
	if InputManager.get_aim_vector(Vector2(0,0)):
		print(InputManager.get_aim_vector(Vector2(0,0)))
		
	pass
