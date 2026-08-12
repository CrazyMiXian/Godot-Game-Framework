class_name Entity
extends Node2D   # 也可用Node3D

signal died()
signal damaged(amount: float, source: Entity)
signal healed(amount: float)

# ID
@export var entity_id: String = ""
# 阵营
@export var faction: Faction
# 实体名称
@export var entity_name: String = ""

var is_alive: bool = true

func _ready() -> void:
	if entity_id.is_empty():
		entity_id = str(get_instance_id())

func take_damage(amount: float, source: Entity = null) -> void:
	if not is_alive:
		return
	
	var final_amount := _calculate_damage(amount, source)
	damaged.emit(final_amount, source)
	
	if final_amount > 0:
		_on_take_damage(final_amount, source)
	
func take_heal(amount: float, source: Entity = null) -> void:
	if not is_alive:
		return
	
	var final_amount := _calculate_heal(amount, source)
	healed.emit(final_amount)
	
	_on_take_heal(final_amount)
	
func die() -> void:
	if not is_alive:
		return
	is_alive = false
	died.emit()
	_on_die()
	
func _calculate_damage(amount: float, source: Entity) -> float:
	return amount

func _calculate_heal(amount: float, source: Entity) -> float:
	return amount

func _on_take_damage(amount: float, source: Entity) -> void:
	pass

func _on_take_heal(amount: float) -> void:
	pass

func _on_die() -> void:
	pass
