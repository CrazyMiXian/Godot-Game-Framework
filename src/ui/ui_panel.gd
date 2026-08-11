class_name UIPanel
extends Control

## 打开动画名称（在 AnimationPlayer 中定义）
@export var open_animation: String = "open"
## 关闭动画名称
@export var close_animation: String = "close"
## 是否在打开时暂停游戏
@export var pause_game: bool = false
## 是否拦截背景输入
@export var block_input: bool = true

@onready var _animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

var _did_pause: bool = false

func on_open(data: Dictionary = {}) -> void:
	_did_pause = false
	
	if pause_game:
		GameManager.pause("GAMEPLAY")
		_did_pause = true

	if block_input:
		mouse_filter = MOUSE_FILTER_STOP

	if _animation_player and _animation_player.has_animation(open_animation):
		_animation_player.play(open_animation)
		await _animation_player.animation_finished

	_on_opened(data)


func on_close() -> void:
	if _did_pause:
		GameManager.unpause("GAMEPLAY")
		_did_pause = false
		

	if _animation_player and _animation_player.has_animation(close_animation):
		_animation_player.play(close_animation)
		await _animation_player.animation_finished

	_on_closed()


## 设置是否可交互（被覆盖时禁用）
func set_interactable(enabled: bool) -> void:
	mouse_filter = MOUSE_FILTER_STOP if enabled else MOUSE_FILTER_IGNORE
	process_mode = PROCESS_MODE_INHERIT if enabled else PROCESS_MODE_DISABLED


## 子类重写以下方法
func _on_opened(data: Dictionary) -> void:
	pass

func _on_closed() -> void:
	pass
