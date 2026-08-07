extends Node

# 输入状态
var _input_history: Array[InputRecord] = []
var _buffer_window: int = 10  # 缓冲窗口（帧数）

class InputRecord:
	var action: String
	var frame: int
	var pressed: bool

	func _init(p_action: String, p_frame: int, p_pressed: bool):
		action = p_action
		frame = p_frame
		pressed = p_pressed
		
func initialize() -> void:
	_ensure_input_map()
		
func _ensure_input_map() -> void:
	# 确保框架默认的输入动作存在
	var default_actions := {
		"accept": [KEY_ENTER, KEY_SPACE],
		"cancel": [KEY_ESCAPE],
		"up": [KEY_UP, KEY_W],
		"down": [KEY_DOWN, KEY_S],
		"left": [KEY_LEFT, KEY_A],
		"right": [KEY_RIGHT, KEY_D],
	}
	# 右摇杆默认输入
	var aim_axes := {
		"aim_left":  [JOY_AXIS_RIGHT_X, -1.0],
		"aim_right": [JOY_AXIS_RIGHT_X,  1.0],
		"aim_up":    [JOY_AXIS_RIGHT_Y, -1.0],
		"aim_down":  [JOY_AXIS_RIGHT_Y,  1.0],
	}

	for action in default_actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key in default_actions[action]:
				var event := InputEventKey.new()
				event.keycode = key
				InputMap.action_add_event(action, event)
				
	for action in aim_axes:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventJoypadMotion.new()
			event.axis = aim_axes[action][0]
			event.axis_value = aim_axes[action][1]
			InputMap.action_add_event(action, event)
	
	LoggerGlobal.info("Using default input settings", self.name)

# 判断逻辑动作是否刚按下
func is_action_just_pressed(action: String, buffer_frames: int = 0) -> bool:
	if Input.is_action_just_pressed(action):
		_record_input(action, true)
		print(action)
		return true
	if buffer_frames > 0:
		return _check_buffer(action, true, buffer_frames)
	return false
	
## 判断逻辑动作是否刚释放
func is_action_just_released(action: String) -> bool:
	return Input.is_action_just_released(action)


## 获取动作的按压值（考虑死区）
func get_action_strength(action: String) -> float:
	return Input.get_action_strength(action)

## 获取移动向量（键盘 WASD + 手柄左摇杆统一）
func get_move_vector() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

## 获取瞄准方向（鼠标/右摇杆）
func get_aim_vector(from_position: Vector2) -> Vector2:
	# 优先手柄右摇杆
	var gamepad_vector := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if gamepad_vector.length() > 0.1:
		return gamepad_vector

	# 回退到鼠标
	return (get_viewport().get_mouse_position() - from_position).normalized()


func _record_input(action: String, pressed: bool) -> void:
	_input_history.append(InputRecord.new(action, Engine.get_process_frames(), pressed))


func _check_buffer(action: String, pressed: bool, buffer_frames: int) -> bool:
	var current_frame := Engine.get_process_frames()
	for record in _input_history:
		if record.action == action and record.pressed == pressed:
			if current_frame - record.frame <= buffer_frames:
				_input_history.erase(record)
				return true
	return false

func _clean_history() -> void:
	var current_frame := Engine.get_process_frames()
	for i in range(_input_history.size() - 1, -1, -1):
		if current_frame - _input_history[i].frame > _buffer_window:
			_input_history.remove_at(i)
