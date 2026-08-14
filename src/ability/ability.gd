class_name Ability
extends Resource

enum TargetType { SELF, SINGLE_ENEMY, SINGLE_ALLY, AREA, DIRECTIONAL, PROJECTILE }

## 技能名称
@export var ability_name: String = ""

## 技能图标
@export var icon: Texture2D

## 冷却时间（秒）
@export var cooldown: float = 1.0

## 消耗的资源（法力/体力等）
@export var cost: Dictionary = {}  # { "mana": 10, "stamina": 5 }

## 目标类型
@export var target_type: TargetType = TargetType.SELF

## 技能范围（AOE 时使用）
@export var range: float = 100.0

## 伤害倍率
@export var damage_multiplier: float = 1.0

## 是否在冷却中
var _on_cooldown: bool = false
var _cooldown_remaining: float = 0.0


## 检查是否可以使用
func can_use(caster: Character) -> bool:
	if _on_cooldown:
		return false

	# 检查消耗
	for resource in cost:
		if caster.get_attribute(resource, 0.0) < cost[resource]:
			return false

	return true


## 使用技能
func use(caster: Character, target = null) -> void:
	if not can_use(caster):
		return

	# 扣除消耗
	for resource in cost:
		caster.attributes.add_bonus(resource, -cost[resource])

	# 开始冷却
	_on_cooldown = true
	_cooldown_remaining = cooldown

	# 执行技能逻辑
	await _execute(caster, target)

	# 冷却计时
	while _cooldown_remaining > 0:
		await caster.get_tree().process_frame
		_cooldown_remaining -= caster.get_process_delta_time()

	_on_cooldown = false


## 子类重写：技能执行逻辑
func _execute(caster: Character, target) -> void:
	pass


## 冷却进度（0.0 - 1.0，UI用）
func get_cooldown_progress() -> float:
	if not _on_cooldown or cooldown <= 0:
		return 0.0
	return 1.0 - (_cooldown_remaining / cooldown)
