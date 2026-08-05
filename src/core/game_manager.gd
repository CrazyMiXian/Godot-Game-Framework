extends Node

## GameManager — 框架入口与生命周期调度器
## 职责：初始化编排、退出清理、暂停代理、全局信号广播

signal framework_ready          ## 所有子系统初始化完成后发射
signal game_quitting            ## 游戏即将退出前发射（用于最终保存）

var _pause_manager: PauseManager = null
var _subsystems: Array[Node] = []
var _is_initialized: bool = false


func _ready() -> void:	
	# 创建内部暂停管理器（不暴露为 Autoload）
	_pause_manager = PauseManager.new()
	add_child(_pause_manager)

	# 收集所有带 initialize() 方法的 Autoload 作为子系统
	_collect_subsystems()

	# 拓扑排序后依次初始化
	var sorted := _topological_sort(_subsystems)
	for subsystem in sorted:
		if subsystem.has_method("initialize"):
			LoggerGlobal.info("Initializing subsystem: %s" % subsystem.name, "GameManager")
			subsystem.initialize()

	_is_initialized = true
	LoggerGlobal.info("Framework initialization complete.", "GameManager")
	emit_signal("framework_ready")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_on_quit_requested()


## ─── 暂停代理 API ───────────────────────────────────────

func pause(layer: StringName = &"GAMEPLAY") -> void:
	_pause_manager.push_pause(layer)


func unpause(layer: StringName = &"GAMEPLAY") -> void:
	_pause_manager.pop_pause(layer)


func is_layer_paused(layer: StringName) -> bool:
	return _pause_manager.is_layer_paused(layer)


## ─── 内部方法 ────────────────────────────────────────────

func _collect_subsystems() -> void:
	# 遍历 Autoload 节点（root 的直接子节点），排除自身
	for child in get_tree().root.get_children():
		if child != self and child.has_method("initialize"):
			_subsystems.append(child)


func _topological_sort(nodes: Array[Node]) -> Array[Node]:
	# Kahn 算法：按 depends_on 声明排序
	# 若子系统未声明依赖或无循环，则保持原始加载顺序
	var in_degree: Dictionary = {}
	var adj: Dictionary = {}
	var name_to_node: Dictionary = {}

	for node in nodes:
		var n := node.name
		name_to_node[n] = node
		in_degree[n] = 0
		adj[n] = []

	for node in nodes:
		if node.has_method("get_dependencies"):
			var deps: Array[StringName] = node.get_dependencies()
			for dep in deps:
				if adj.has(dep):
					adj[dep].append(node.name)
					in_degree[node.name] += 1

	var queue: Array[String] = []
	for key in in_degree:
		if in_degree[key] == 0:
			queue.append(key)

	var result: Array[Node] = []
	while not queue.is_empty():
		var current: String = queue.pop_front()
		result.append(name_to_node[current])
		for neighbor in adj[current]:
			in_degree[neighbor] -= 1
			if in_degree[neighbor] == 0:
				queue.append(neighbor)

	# 如果存在循环依赖，result 长度 < nodes 长度，记录警告
	if result.size() < nodes.size():
		LoggerGlobal.warn("Circular dependency detected in subsystem initialization! Falling back to load order.", "GameManager")
		return nodes

	return result


func _on_quit_requested() -> void:
	LoggerGlobal.info("Quit requested, shutting down subsystems...", "GameManager")
	emit_signal("game_quitting")

	# 逆序关闭子系统
	var sorted := _topological_sort(_subsystems)
	sorted.reverse()
	for subsystem in sorted:
		if subsystem.has_method("shutdown"):
			LoggerGlobal.info("Shutting down subsystem: %s" % subsystem.name, "GameManager")
			subsystem.shutdown()

	get_tree().quit()
