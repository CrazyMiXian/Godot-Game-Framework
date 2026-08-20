extends Node

func _ready() -> void:
	RoomManager.room_host =$RoomHost     # ← 关键：注入
	RoomManager.player = $Player
