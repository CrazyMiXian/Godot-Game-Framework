extends Node

const SAVE_DIR := "user://saves/"
const SAVE_EXTENSION := ".sav"
const MAX_SLOTS := 10

var _current_slot: int = 0


## 获取存档槽列表（含元数据）
func get_slots() -> Array[Dictionary]:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var slots: Array[Dictionary] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return slots

	for i in range(MAX_SLOTS):
		var filename := "slot_%03d%s" % [i, SAVE_EXTENSION]
		if dir.file_exists(filename):
			var meta := _read_slot_meta(i)
			slots.append(meta)
		else:
			slots.append({"id": i, "empty": true})

	return slots


## 保存
func save(slot: int, save_data: SaveData) -> bool:
	_ensure_dir()
	var path := _slot_path(slot)

	# 更新元数据
	save_data.slot_id = slot
	save_data.timestamp = Time.get_unix_time_from_system()
	save_data.version = SaveData.CURRENT_VERSION

	# 序列化
	var packed := save_data.serialize()

	# 写入文件
	var file := FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, _encryption_key())
	if file == null:
		LoggerGlobal.error("无法创建存档文件: %s" % path, self)
		return false

	file.store_var(packed, true)  # true = 完全序列化（支持嵌套对象）
	file.close()

	# 保存元数据（独立的快读文件）
	_write_slot_meta(slot, save_data)

	EventBus.emit("save_completed", {"slot": slot})
	LoggerGlobal.info("存档保存成功: slot %d" % slot, self)
	return true


## 读取
func load(slot: int) -> SaveData:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		LoggerGlobal.warn("存档不存在: slot %d" % slot, self)
		return null

	var file := FileAccess.open_encrypted_with_pass(path, FileAccess.READ, _encryption_key())
	if file == null:
		LoggerGlobal.error("无法读取存档文件: %s" % path, self)
		return null

	var data = file.get_var(true)
	file.close()

	if data == null:
		return null

	var save_data := SaveData.new()
	save_data.deserialize(data)

	# 版本迁移
	if save_data.version < SaveData.CURRENT_VERSION:
		_migrate(save_data)

	_current_slot = slot
	EventBus.emit("load_completed", {"slot": slot})
	return save_data


## 删除存档
func delete(slot: int) -> bool:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	_delete_slot_meta(slot)
	return true


func _slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%03d%s" % [slot, SAVE_EXTENSION]


func _encryption_key() -> String:
	# 生产环境中应从更安全的地方获取
	return "ggf_default_encryption_key_2024"


func _ensure_dir() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _read_slot_meta(slot: int) -> Dictionary:
	var path := SAVE_DIR + "meta_%03d.json" % slot
	if not FileAccess.file_exists(path):
		return {"id": slot, "empty": true}

	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	json.parse(text)
	return json.data


func _write_slot_meta(slot: int, save_data: SaveData) -> void:
	var meta := {
		"id": slot,
		"timestamp": save_data.timestamp,
		"version": save_data.version,
		"play_time": save_data.play_time,
		"player_name": save_data.player_name,
		"scene": save_data.current_scene,
		"empty": false,
	}
	var path := SAVE_DIR + "meta_%03d.json" % slot
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(meta, "\t"))
	file.close()


func _migrate(save_data: SaveData) -> void:
	# 逐版本迁移（链式）
	while save_data.version < SaveData.CURRENT_VERSION:
		match save_data.version:
			1:
				_migrate_v1_to_v2(save_data)
			2:
				_migrate_v2_to_v3(save_data)
			_:
				save_data.version += 1

func _delete_slot_meta(slot: int) -> void:
	var path := SAVE_DIR + "meta_%03d.json" % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


## V1 → V2 迁移
func _migrate_v1_to_v2(save_data: SaveData) -> void:
	# 示例：v2 新增了 inventory 字段，v1 存档没有该字段
	# 反序列化后 save_data.inventory 为 null/默认值，这里赋予初始值
	if not save_data.has("inventory"):
		save_data.inventory = []
	
	# 示例：重命名字段
	# if save_data.has("old_field_name"):
	#     save_data.new_field_name = save_data.old_field_name
	#     save_data.erase("old_field_name")
	
	save_data.version = 2


## V2 → V3 迁移
func _migrate_v2_to_v3(save_data: SaveData) -> void:
	# 示例：v3 将 play_time 从秒改为毫秒
	# save_data.play_time = int(save_data.play_time * 1000)
	
	# 示例：新增枚举字段，给旧存档设置默认值
	# if not save_data.has("difficulty"):
	#     save_data.difficulty = Difficulty.NORMAL
	
	save_data.version = 3
