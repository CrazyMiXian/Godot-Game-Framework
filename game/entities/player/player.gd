# player.gd
extends CharacterBody2D

@export var move_speed: float = 200.0

@onready var stats: Character = $Stats

func _ready() -> void:
	# 死亡时处理根节点（Stats 的 _on_die 只会 queue_free 它自己）
	stats.died.connect(_on_stats_died)

func _physics_process(delta: float) -> void:
	velocity = InputManager.get_move_vector() * move_speed
	move_and_slide()                      # Godot 4 无参数

## 受击入口：玩家脚本只转发，计算交给框架 Character
func take_damage(amount: float, source: Entity = null) -> void:
	stats.take_damage(amount, source)

func _on_stats_died() -> void:
	# 播放死亡动画、掉落物等，然后
	queue_free()
