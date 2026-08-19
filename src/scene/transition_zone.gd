# transition_zone.gd
extends Area2D

@export_file("*.tscn") var target_scene: String          # 目标场景，Inspector 里选
@export var target_spawn_id: String = "default"          # 目标场景里的出生点名称

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# 只对玩家响应（玩家节点记得加 "player" group）
	if not body.is_in_group("player"):
		return
	# 防止同帧重复触发（change_scene 异步，进入后立刻关监测）
	set_deferred("monitoring", false)
	SceneManager.change_scene(target_scene, {"spawn_id": target_spawn_id})
