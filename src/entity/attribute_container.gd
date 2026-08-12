class_name AttributeContainer
extends Resource

# 基础属性 { "strength": 10.0, "agility": 8.0, ... }
@export var base: Dictionary = {}

# 加成（来自装备/Buff等） { "strength": {"bonus": 2.0, "multiplier": 0.1} }
var _bonuses: Dictionary = {}

# 获取属性
func get_value(attr_name: String, default: float = 0.0) -> float:
	var base_value: float = base.get(attr_name, default)
	var bonus_data: Dictionary = _bonuses.get(attr_name, {})

	var flat_bonus: float = bonus_data.get("flat", 0.0)
	var multiplier: float = bonus_data.get("multiplier", 0.0)

	return (base_value + flat_bonus) * (1.0 + multiplier)

# 添加buff
func add_bonus(attr_name: String, flat: float = 0.0, multiplier: float = 0.0, source_id: String = "") -> void:
	if not _bonuses.has(attr_name):
		_bonuses[attr_name] = {"flat": 0.0, "multiplier": 0.0, "sources": {}}

	_bonuses[attr_name]["flat"] += flat
	_bonuses[attr_name]["multiplier"] += multiplier

	if not source_id.is_empty():
		_bonuses[attr_name]["sources"][source_id] = {"flat": flat, "multiplier": multiplier}

# 移除buff
func remove_bonus(attr_name: String, source_id: String) -> void:
	if not _bonuses.has(attr_name):
		return

	var sources: Dictionary = _bonuses[attr_name].get("sources", {})
	if sources.has(source_id):
		var entry = sources[source_id]
		_bonuses[attr_name]["flat"] -= entry["flat"]
		_bonuses[attr_name]["multiplier"] -= entry["multiplier"]
		sources.erase(source_id)
