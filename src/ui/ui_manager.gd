extends Node

## UI 面板栈
var _panel_stack: Array[UIPanel] = []

## UI Canvas 层引用
var _ui_layer: CanvasLayer

func initialize() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "UILayer"
	_ui_layer.layer = 100  # 确保在一切之上
	get_tree().root.add_child(_ui_layer)
	# 不移除——持续存活
	_ui_layer.owner = get_tree().root


## 打开一个面板（场景路径）
func show(panel_path: String, data: Dictionary = {}) -> UIPanel:
	var scene: PackedScene = load(panel_path)
	var panel: UIPanel = scene.instantiate()
	_ui_layer.add_child(panel)

	# 如果已有面板，把之前的设为非交互
	if not _panel_stack.is_empty():
		_panel_stack.back().set_interactable(false)

	_panel_stack.append(panel)
	panel.on_open(data)

	return panel


## 关闭当前最顶层面板
func close_top() -> void:
	if _panel_stack.is_empty():
		return

	var panel = _panel_stack.pop_back()
	await panel.on_close()

	# 恢复上一层交互
	if not _panel_stack.is_empty():
		_panel_stack.back().set_interactable(true)

	panel.queue_free()


## 关闭到指定面板
func close_to(panel: UIPanel) -> void:
	while not _panel_stack.is_empty() and _panel_stack.back() != panel:
		close_top()


## 显示弹窗（链式 API）
#func show_dialog(dialog_type: String) -> DialogBuilder:
#	return DialogBuilder.new(dialog_type, _ui_layer)
