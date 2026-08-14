class_name StateMachine
extends Node

signal state_changed(from: String, to: String)

## 状态字典 { "idle": State, "walk": State, ... }
var _states: Dictionary = {}

## 转换表 [ Transition, Transition, ... ]
var _transitions: Array[Transition] = []
var _any_transitions: Array[Transition] = []  # 从任意状态触发的转换

## 当前状态
var current_state: State = null
var previous_state: State = null

## 状态机是否激活
var active: bool = true:
	set(v):
		active = v
		if not active and current_state:
			current_state.on_exit()

class Transition:
	var from_state: String
	var to_state: String
	var condition: Callable  # func() -> bool
	var priority: int = 0

	func _init(p_from: String, p_to: String, p_condition: Callable, p_priority: int = 0):
		from_state = p_from
		to_state = p_to
		condition = p_condition
		priority = p_priority


## 添加状态
func add_state(p_name: String, p_state: State) -> void:
	p_state.machine = self
	_states[p_name] = p_state


## 创建并添加一个简单状态
func create_state(p_name: String, p_enter: Callable = Callable(), p_update: Callable = Callable(), p_physics_update: Callable = Callable(), p_exit: Callable = Callable()) -> State:
	var state := State.new()
	state.name = p_name
	state.enter_callback = p_enter
	state.update_callback = p_update
	state.physics_update_callback = p_physics_update
	state.exit_callback = p_exit
	add_state(p_name, state)
	return state


## 添加转换
func add_transition(p_from: String, p_to: String, p_condition: Callable, p_priority: int = 0) -> void:
	_transitions.append(Transition.new(p_from, p_to, p_condition, p_priority))
	_transitions.sort_custom(func(a, b): return a.priority > b.priority)


## 添加任意状态转换
func add_any_transition(p_to: String, p_condition: Callable, p_priority: int = 0) -> void:
	_any_transitions.append(Transition.new("", p_to, p_condition, p_priority))
	_any_transitions.sort_custom(func(a, b): return a.priority > b.priority)


## 设置初始状态并启动
func start(p_initial_state: String) -> void:
	if not _states.has(p_initial_state):
		push_error("状态机: 初始状态 '%s' 未定义" % p_initial_state)
		return
	_change_state(p_initial_state)


func _process(delta: float) -> void:
	if not active or current_state == null:
		return
	_check_transitions()
	current_state.on_update(delta)


func _physics_process(delta: float) -> void:
	if not active or current_state == null:
		return
	current_state.on_physics_update(delta)


func _check_transitions() -> void:
	# 优先检查 any_transition（高优先级）
	for trans in _any_transitions:
		if trans.condition.call():
			_change_state(trans.to_state)
			return

	# 检查当前状态的特定转换
	for trans in _transitions:
		if trans.from_state == current_state.name:
			if trans.condition.call():
				_change_state(trans.to_state)
				return


func _change_state(p_to: String) -> void:
	var new_state: State = _states.get(p_to)
	if new_state == null:
		push_error("状态机: 目标状态 '%s' 未定义" % p_to)
		return

	if current_state:
		current_state.on_exit()

	previous_state = current_state
	state_changed.emit(previous_state.name if previous_state else "", p_to)

	current_state = new_state
	current_state.on_enter()


## 返回上一状态
func revert_to_previous() -> void:
	if previous_state:
		_change_state(previous_state.name)

# 使用示例
'''
# player.gd
@onready var fsm: StateMachine = $StateMachine

func _ready():
    # 创建状态
    fsm.create_state("idle",
        func(): anim.play("idle"),           # enter
        func(d): pass,                       # update
        func(d): pass,                       # physics
        func(): pass                         # exit
    )
    
    fsm.create_state("run",
        func(): anim.play("run"),
        func(d): velocity = input_dir * speed,
        func(d): move_and_slide(),
        func(): velocity = Vector2.ZERO
    )
    
    # 添加转换
    fsm.add_transition("idle", "run", 
        func(): return Input.get_vector(...) != Vector2.ZERO)
    fsm.add_transition("run", "idle", 
        func(): return Input.get_vector(...) == Vector2.ZERO)
    
    # 全局转换：任何状态下按ESC暂停
    fsm.add_any_transition("paused", 
        func(): return Input.is_action_just_pressed("pause"), 
        100)  # 高优先级
    
    fsm.start("idle")
'''
