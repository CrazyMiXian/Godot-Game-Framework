class_name CooldownComponent
extends AbilityComponent

@export var cooldown: float = 1.0
var _on_cooldown: bool = false
var _remaining: float = 0.0


func on_cast_start(caster: Character, target) -> void:
	_on_cooldown = true
	_remaining = cooldown
