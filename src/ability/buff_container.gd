class_name BuffContainer
extends Node

var _buffs: Array[Buff] = []
var host: Character

func _init(p_host: Character):
	host = p_host


func _process(delta: float) -> void:
	for buff in _buffs.duplicate():
		buff.on_tick(delta)


func apply_buff(buff_template: Buff, source_id: String = "") -> Buff:
	# 检查是否已有同名 Buff
	var existing := _find_buff(buff_template.buff_name)
	if existing:
		match buff_template.stack_policy:
			Buff.StackPolicy.REFRESH_DURATION:
				existing.remaining_time = buff_template.duration
				return existing
			Buff.StackPolicy.ADD_STACK:
				if existing.current_stacks < existing.max_stacks:
					existing.current_stacks += 1
					existing.remaining_time = buff_template.duration
				return existing
			Buff.StackPolicy.REJECT:
				return existing
			Buff.StackPolicy.INDEPENDENT:
				pass  # 继续创建新的

	# 创建新 Buff 实例
	var new_buff := buff_template.duplicate(true)  # true = 深层复制
	new_buff.source_id = source_id
	new_buff.container = self

	var owner_char := host as Character
	if owner_char:
		new_buff.on_apply(owner_char)

	_buffs.append(new_buff)
	return new_buff


func remove_buff(buff: Buff) -> void:
	if not _buffs.has(buff):
		return
	buff.on_remove()
	_buffs.erase(buff)


func _find_buff(buff_name: String) -> Buff:
	for buff in _buffs:
		if buff.buff_name == buff_name:
			return buff
	return null


func on_damage_taken(amount: float, source: Entity) -> float:
	var result := amount
	for buff in _buffs:
		result = buff.on_damage_taken(result, source)
	return result
