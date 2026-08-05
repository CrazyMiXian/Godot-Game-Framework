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
	pass

# 压入场景(当前场景保留)
func push_scene(path: String, data: Dictionary = {}, transition_type: TransitionType = TransitionType.FADE) -> void:
	pass

# 弹出当前场景，恢复上一层
func pop_scene(transition_type: TransitionType = TransitionType.FADE) -> void:
	pass

# 
func add_sub_scene(layer_name, path, data) -> void:
	pass

# 切换场景的核心代码
func _change_scene_internal(path: String, data: Dictionary, transition_type: TransitionType, push: bool) -> void:
	await _play_transition(transition_type, true)
	# TODO:未完成

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
