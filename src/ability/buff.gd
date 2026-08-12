class_name Buff
extends Resource

enum StackPolicy { INDEPENDENT, REFRESH_DURATION, ADD_STACK, REJECT }

@export var buff_name: String = ""
@export var icon: Texture2D
@export var duration: float = 5.0          # -1 = 永久
@export var max_stacks: int = 1
@export var stack_policy: StackPolicy = StackPolicy.REFRESH_DURATION

## 属性修改 { "strength": {"flat": 5.0, "multiplier": 0.0} }
@export var attribute_modifiers: Dictionary = {}

## 周期性效果间隔（秒，0 = 无周期效果）
@export var tick_interval: float = 0.0

## Buff 来源实体 ID
var source_id: String = ""
var current_stacks: int = 1
var remaining_time: float = 0.0
var _tick_timer: float = 0.0

## 所属容器
var container: BuffContainer = null
var owner_character: Character = null


func on_apply(character: Character) -> void:
	owner_character = character
	remaining_time = duration
	_tick_timer = tick_interval

	# 应用属性修改
	for attr in attribute_modifiers:
		var mod = attribute_modifiers[attr]
		character.attributes.add_bonus(attr, mod.get("flat", 0.0), mod.get("multiplier", 0.0), buff_name)


func on_remove() -> void:
	# 移除属性修改
	for attr in attribute_modifiers:
		owner_character.attributes.remove_bonus(attr, buff_name)


func on_tick(delta: float) -> void:
	if duration > 0:
		remaining_time -= delta
		if remaining_time <= 0:
			container.remove_buff(self)
			return

	if tick_interval > 0:
		_tick_timer -= delta
		if _tick_timer <= 0:
			_tick_timer = tick_interval
			_on_tick_effect()


func _on_tick_effect() -> void:
	# 子类重写（或通过回调）
	pass


func on_damage_taken(amount: float, source: Entity) -> float:
	return amount
