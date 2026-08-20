# room_manager.gd —— 作为 autoload 或挂 Main 下
extends Node

signal room_changed(room_id: String, entry_direction: String)

## 地图状态 { room_id: { "explored": bool, "cleared": bool } } —— 小地图数据源
var map_state: Dictionary = {}
var current_room_id: String = ""

var room_host: Node2D          # 由 Main 注入：Main 里挂这个脚本并赋值
var player: CharacterBody2D    # 同样注入

func load_room(room_scene: PackedScene, room_id: String, entry_direction: String = "default") -> void:
	# 1. 卸载旧房间（只清 RoomHost，玩家不受影响）
	for child in room_host.get_children():
		child.queue_free()

	# 2. 加载新房间
	var room := room_scene.instantiate()
	room_host.add_child(room)
	current_room_id = room_id

	# 3. 记录探索状态
	if not map_state.has(room_id):
		map_state[room_id] = {"explored": true, "cleared": false}
	else:
		map_state[room_id]["explored"] = true

	# 4. 玩家放到对应入口（spawn 点在房间场景里）
	var spawn := room.get_node_or_null("SpawnPoints/" + entry_direction) as Marker2D
	if spawn and player:
		player.global_position = spawn.global_position

	room_changed.emit(room_id, entry_direction)
