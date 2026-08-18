class_name Character
extends Entity

signal health_changed(current: float, maximum: float)
signal level_up(new_level: int)

# 属性
@export var attributes: AttributeContainer

# 生命值
@export var max_health: float = 100.0:
	set(v):
		max_health = maxf(1.0, v)
		if current_health > max_health:
			current_health = max_health
var current_health: float = 100.0:
	set(v):
		var old := current_health
		current_health = clampf(v, 0.0, max_health)
		if current_health != old:
			health_changed.emit(current_health, max_health)
			
# 移动速度
@export var move_speed: float = 200.0

# 等级
@export var level: int = 1

# Buff 容器
var buff_container: BuffContainer

func _ready() -> void:
	super._ready()
	current_health = max_health
	buff_container = BuffContainer.new(self); add_child(buff_container)


func _calculate_damage(amount: float, source: Entity) -> float:
	# 应用属性加成的伤害计算
	var defense := attributes.get_value("defense", 0.0)
	var reduction := defense / (defense + 100.0)  # 护甲减伤公式
	var final := amount * (1.0 - reduction)

	# 让 Buff 修改最终伤害
	final = buff_container.on_damage_taken(final, source)

	return maxf(1.0, final)  # 最少 1 点伤害


func _on_die() -> void:
	queue_free()


## 获取属性值（从 AttributeContainer）
func get_attribute(attr_name: String, default: float = 0.0) -> float:
	if attributes:
		return attributes.get_value(attr_name, default)
	return default
