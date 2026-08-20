# room_door.gd
extends Area2D

@export var target_scene: PackedScene      # 相邻房间场景
@export var target_room_id: String         # 相邻房间 ID
@export var entry_direction: String        # 进入相邻房间时从哪个门出现，如 "west"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	set_deferred("monitoring", false)       # 防重复触发
	RoomManager.load_room.call_deferred(target_scene, target_room_id, entry_direction)
