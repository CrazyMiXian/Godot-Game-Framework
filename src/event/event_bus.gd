extends  Node

## 监听器存储: {event_name:[{id, callable, once}]}
var _listeners: Dictionary = {}
var _listener_id_counter: int = 0

# 注册一个持久监听
func on(event_name: String, callable: Callable) -> int:
	return _add_listener(event_name, callable, false)

# 注册一个一次性监听
func once(event_name: String, callable: Callable = ) -> int:
	return _add_listener(event_name, callable, true)

# 关闭一个监听, 支持用ID或使用名称关闭
func off(event_or_id, callable: Callable = Callable()) -> void:
	if event_or_id is int:
		_off_by_id(event_or_id)
	elif event_or_id is String and callable.is_valid():
		_off_by_callable(event_or_id, callable)
		
# 清除某事件的所有监听
func clear_event(event_name: String) -> void:
	_listeners.erase(event_name)

# 清除所有监听
func clear_all() -> void:
	_listeners.clear()

# 发射事件
func emit(event_name: String, data = null) -> void:
	# 调试日志
	LoggerGlobal.debug("Emit event: event_name = %s, data = %s" % [event_name, data], self.name)

	if not _listeners.has(event_name):
		return

	# 复制一份再遍历（因为回调可能修改 _listeners）
	var listeners: Array = _listeners[event_name].duplicate()

	for listener in listeners:
		if listener.once:
			_remove_listener_entry(event_name, listener.id)

		if listener.callable.is_valid():
			# 根据数据是否为 null 决定传参
			if data == null:
				listener.callable.call()
			else:
				listener.callable.call(data)

## 发射延迟事件（下一帧触发）
func emit_deferred(event_name: String, data = null) -> void:
	call_deferred("emit", event_name, data)


## ========== 内部使用 ===========
# 添加监听字典
func _add_listener(event_name: String, callable: Callable, once: bool) -> int:
	_listener_id_counter += 1
	var id : int = _listener_id_counter
	
	if not _listeners.has(event_name):
		_listeners[event_name] = []
		
	_listeners[event_name].append({
		"id": id,
		"callable": callable,
		"once": once,
	})
	LoggerGlobal.debug("Add event: event_name = %s, id = %s, once = %s" % [event_name, id, once], self.name)
	
	return id

# 移除单个监听
func _remove_listener_entry(event_name: String, listener_id: int) -> void:
	if not _listeners.has(event_name):
		return
	var listeners: Array = _listeners[event_name]
	for i in range(listeners.size() - 1, -1, -1):
		if listeners[i].id == listener_id:
			LoggerGlobal.debug("Remove event: event_name = %s, id = %s" % [event_name, listener_id], self.name)
			listeners.remove_at(i)
			return
			
func _off_by_id(listener_id: int) -> void:
	for event_name in _listeners:
		var listeners: Array = _listeners[event_name]
		for i in range(listeners.size() - 1, -1, -1):
			if listeners[i].id == listener_id:
				LoggerGlobal.debug("Remove event: event_name = %s, id = %s" % [event_name, listener_id], self.name)
				listeners.remove_at(i)
				return

func _off_by_callable(event_name: String, callable: Callable) -> void:
	if not _listeners.has(event_name):
		return
	var listeners: Array = _listeners[event_name]
	for i in range(listeners.size() - 1, -1, -1):
		if listeners[i].callable == callable:
			LoggerGlobal.debug("Remove event: event_name = %s, id = %s" % [event_name, listeners[i].id], self.name)
			listeners.remove_at(i)


''' 使用示例
# 玩家死亡发射事件
EventBus.emit("player_died", {
    "player_id": 1,
    "killer": "enemy_orc",
    "position": player.global_position,
})

# UI 监听
var _listener_id: int

func _ready():
    _listener_id = EventBus.on("player_died", _on_player_died)

func _on_player_died(data: Dictionary):
    print("玩家 %d 被 %s 击杀" % [data.player_id, data.killer])

func _exit_tree():
    EventBus.off(_listener_id)  # 重要：防止悬垂引用
'''
