class_name PauseManager
extends Node

## PauseManager — 多层暂停栈管理器
## 支持 GAMEPLAY / UI / SYSTEM 三层暂停，高优先级层可覆盖低优先级层
## 由 GameManager 内部持有，不作为独立 Autoload

enum Layer {
	GAMEPLAY,   ## 游戏逻辑暂停（最低优先级）
	UI,         ## UI 交互暂停（中优先级）
	SYSTEM,     ## 系统级暂停如过场动画（最高优先级）
}

const LAYER_PRIORITY: Dictionary = {
	&"GAMEPLAY": 0,
	&"UI": 1,
	&"SYSTEM": 2,
}

var _pause_stack: Array[StringName] = []
#var _base_process_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT


func push_pause(layer: StringName = &"GAMEPLAY") -> void:
	if layer not in LAYER_PRIORITY:
		push_error("PauseManager: Unknown pause layer '%s'" % layer)
		return

	if layer in _pause_stack:
		return  # 同层重复压入忽略

	_pause_stack.append(layer)
	_apply_pause()


func pop_pause(layer: StringName = &"GAMEPLAY") -> void:
	var idx := _pause_stack.find(layer)
	if idx == -1:
		push_warning("PauseManager: Attempted to pop non-existent layer '%s'" % layer)
		return

	_pause_stack.remove_at(idx)
	_apply_pause()


func is_layer_paused(layer: StringName) -> bool:
	return layer in _pause_stack


func get_active_layers() -> Array[StringName]:
	return _pause_stack.duplicate()


func clear_all() -> void:
	_pause_stack.clear()
	_apply_pause()


## ─── 内部方法 ────────────────────────────────────────────

func _apply_pause() -> void:
	if _pause_stack.is_empty():
		# 栈空 → 恢复运行
		get_tree().paused = false
		#process_mode = _base_process_mode
	else:
		# 栈非空 → 暂停游戏树，自身保持 PROCESS_MODE_ALWAYS 以响应 unpause
		get_tree().paused = true
		#process_mode = Node.PROCESS_MODE_ALWAYS
