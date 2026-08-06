extends Node

# 场景加载进度信号
signal load_progress(progress: float)
# 场景切换完成信号
signal scene_changed(new_scene_path: String)
# 场景切换效果
enum TransitionType {NONE, FADE, SLIDE_LEFT, SLIDE_RIGHT, CUSTOM}
# 场景栈
var _scene_stack: Array[SceneStackEntry] = []


class SceneStackEntry:
	var path: String
	var node: Node  # 挂起的场景根节点
	var data: Dictionary  # 传递给场景的参数
	
	func _init(p_path: String = "", p_node: Node = null, p_data: Dictionary = {}) -> void:
		path = p_path
		node = p_node
		data = p_data

func initialize() -> void:
	_create_transition_layer()

# 创建过渡效果: 在根节点通过预设画面创建一个名为"SceneTransition"的场景包
func _create_transition_layer() -> void:
	var transition_scene := load("res://src/scene/scene_transition.tscn") as PackedScene
	var transition := transition_scene.instantiate()
	transition.name = "SceneTransition"
	get_tree().root.call_deferred("add_child", transition)

# 切换场景(替代当前场景)
func change_scene(path: String, data: Dictionary = {}, transition_type: TransitionType = TransitionType.FADE) -> void:
	_change_scene_internal(path, data, transition_type, false)

# 压入场景(当前场景保留)
func push_scene(path: String, data: Dictionary = {}, transition_type: TransitionType = TransitionType.FADE) -> void:
	_change_scene_internal(path, data, transition_type, true)

# 弹出当前场景，恢复上一层
func pop_scene(transition_type: TransitionType = TransitionType.FADE) -> void:
	if _scene_stack.is_empty():
		LoggerGlobal.warn("Scene stack is empty, failed to pop", self.name)
		return
	
	await  _play_transition(transition_type, true)
	
	# 移除当前场景
	var current = _scene_stack.pop_back()
	
	if not _scene_stack.is_empty():
		var previous = _scene_stack.back()
		previous.node.process_mode = Node.PROCESS_MODE_INHERIT
		if previous.node.has_method("_on_scene_resumed"):
			previous.node._on_scene_resumed(current.data)
		
		
func add_sub_scene(layer_name, path, data) -> void:
	pass

# 切换场景的核心代码
func _change_scene_internal(path: String, data: Dictionary, transition_type: TransitionType, push: bool) -> void:
	await _play_transition(transition_type, true)
	
	var current_root := get_tree().current_scene
	# 挂起场景
	if current_root and not push:
		current_root.queue_free()
	else:
		current_root.process_mode = Node.PROCESS_MODE_DISABLED
		_scene_stack.back().node = current_root
		
	# 加载场景
	var loader = ResourceLoader.load_threaded_request(path)
	if loader != OK:
		LoggerGlobal.error("Failed to load scene - %s" % path, self.name)
		return
	
	# 显示加载进度
	while true:
		var status := ResourceLoader.load_threaded_get_status(path)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				var progress_array := []
				load_progress.emit(progress_array[0] * 100.0 if progress_array.size() > 0 else 0.0)
			ResourceLoader.THREAD_LOAD_LOADED:
				break
			ResourceLoader.THREAD_LOAD_FAILED:
				LoggerGlobal.error("Failed to load scene resource - %s" % path, self.name)
				return
	await get_tree().process_frame
		
	var new_scene: PackedScene = ResourceLoader.load_threaded_get(path)
	var new_root := new_scene.instantiate()
		
	# 压入场景栈
	_scene_stack.append(SceneStackEntry.new(path, new_root, data))

	# 添加到场景树
	get_tree().root.add_child(new_root)
	get_tree().current_scene = new_root

	# 传递数据
	if new_root.has_method("_on_scene_enter"):
		new_root._on_scene_enter(data)

	scene_changed.emit(path)

	await _play_transition(transition_type, false)

func _play_transition(transition_type: TransitionType, is_out: bool) -> void:
	if transition_type == TransitionType.NONE:
		return
	
	var transition := get_tree().root.get_node_or_null("SceneTransition")
	if transition == null:
		return
	
	match transition_type:
		TransitionType.FADE:
			if is_out:
				await  transition.fade_out()
			else:
				await  transition.fade_in()
		# TODO:更多效果等待后续拓展
