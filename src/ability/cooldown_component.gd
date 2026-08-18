class_name CooldownComponent
extends AbilityComponent

@export var cooldown: float = 1.0

var _on_cooldown: bool = false
var _remaining: float = 0.0

func is_ready() -> bool:
	return not _on_cooldown

func get_progress() -> float:
	if not _on_cooldown or cooldown <= 0.0:
		return 0.0
	return 1.0 - (_remaining / cooldown)

func on_cast_start(caster: Character, target) -> void:
	_on_cooldown = true
	_remaining = cooldown

func tick(delta: float) -> void:
	if not _on_cooldown:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		_remaining = 0.0
		_on_cooldown = false
