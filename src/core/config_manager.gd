extends Node

var _config : Dictionary = {}
const CONFIG_PATH := "res://config.json"

#func _ready() -> void:
#	initialize()

func initialize() -> void:
	load_config()

# 加载配置文件
func load_config() -> void:
	# 没有配置文件则使用默认配置
	if not FileAccess.file_exists(CONFIG_PATH):
		LoggerGlobal.warn("Config file - %s is not exist, using default config." % CONFIG_PATH, self.name)
		_config = _default_config()
		return
	
	# 有配置文件但是无法读取则报错
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		LoggerGlobal.error("Failed to load config file - %s" % CONFIG_PATH, self.name)
		_config = _default_config()
		return
	
	var text := file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error := json.parse(text)
	if error != OK:
		LoggerGlobal.error("Failed to load config file at line - %s" % json.get_error_line(), self.name)
		return
		
	_config = json.data
	LoggerGlobal.info("Successfully loaded config file - %s" % CONFIG_PATH, self.name)


# 获取配置文件中的数据
func get_value(path:String, default = null):
	var keys := path.split(".")
	var current = _config
	for key in keys:
		if not current is Dictionary or not current.has(key):
			return default
		current = current[key]
	return current


# 无法找到配置文件时，使用默认配置
func _default_config() -> Dictionary:
	return{
		"audio": {
			"master_volume": 1.0
		}
	}
