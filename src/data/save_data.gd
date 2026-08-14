class_name SaveData
extends Resource

## 存档结构版本号
const CURRENT_VERSION := 1

@export var version: int = CURRENT_VERSION
@export var slot_id: int = 0
@export var timestamp: int = 0
@export var play_time: float = 0.0
@export var player_name: String = ""
@export var current_scene: String = ""

## 游戏专用数据（Dictionary，存储任意结构）
## 注意：Godot 的 @export var 对 Dictionary 支持有限，
## 因此这里使用序列化/反序列化模式
var game_data: Dictionary = {}


## 序列化为可存储的 Dictionary
func serialize() -> Dictionary:
	return {
		"version": version,
		"slot_id": slot_id,
		"timestamp": timestamp,
		"play_time": play_time,
		"player_name": player_name,
		"current_scene": current_scene,
		"game_data": game_data,
	}


## 从 Dictionary 恢复
func deserialize(data: Dictionary) -> void:
	version = data.get("version", 0)
	slot_id = data.get("slot_id", 0)
	timestamp = data.get("timestamp", 0)
	play_time = data.get("play_time", 0.0)
	player_name = data.get("player_name", "")
	current_scene = data.get("current_scene", "")
	game_data = data.get("game_data", {})
