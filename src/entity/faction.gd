class_name Faction
extends Resource

@export var faction_id: String = ""
@export var faction_name: String = ""
@export var friendly_to: Array[String] = []   # 友方阵营 ID 列表
@export var hostile_to: Array[String] = []    # 敌方阵营 ID 列表


enum Relation { FRIENDLY, NEUTRAL, HOSTILE }


func get_relation(other: Faction) -> Relation:
	if not other:
		return Relation.NEUTRAL
	if other.faction_id in hostile_to:
		return Relation.HOSTILE
	if other.faction_id in friendly_to or other.faction_id == faction_id:
		return Relation.FRIENDLY
	return Relation.NEUTRAL


func is_hostile_to(other: Faction) -> bool:
	return get_relation(other) == Relation.HOSTILE
