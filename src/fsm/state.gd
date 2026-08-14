class_name State
extends RefCounted

var name: String = ""
var machine: StateMachine = null

var enter_callback: Callable
var update_callback: Callable
var physics_update_callback: Callable
var exit_callback: Callable

## 状态进入以来的时间
var elapsed_time: float = 0.0


func on_enter() -> void:
	elapsed_time = 0.0
	if enter_callback.is_valid():
		enter_callback.call()


func on_update(delta: float) -> void:
	elapsed_time += delta
	if update_callback.is_valid():
		update_callback.call(delta)


func on_physics_update(delta: float) -> void:
	if physics_update_callback.is_valid():
		physics_update_callback.call(delta)


func on_exit() -> void:
	if exit_callback.is_valid():
		exit_callback.call()
