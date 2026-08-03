extends  Node

enum Level{DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3}

## 配置项
# 日志最低等级
var min_level : Level = Level.DEBUG
# var buffer_size: int = 10
# 日志路径(自动生成)
var _log_path : String = ""
# 最大日志存在数量
const MAX_LOG_FILES := 5

# 内部项
signal log_added(entry: Dictionary)

func _ready() -> void:
	initialize()
	pass

# 初始化
func initialize() -> void:
	print("[Logger]:准备就绪")
	# 获取系统时间并给日志命名
	var time_str: String = Time.get_datetime_string_from_system()
	time_str = time_str.replace(":","-")
	_log_path = "user://" + time_str + ".log"
	print("[Logger]:创建日志 - %s"%_log_path)
	var _file := FileAccess.open(_log_path,FileAccess.WRITE)
	if _file:
		_file.store_line("=========================")
		_file.store_line("Logger - %s"%Time.get_datetime_string_from_system())
		_file.store_line("=========================")
		print("[Logger]:日志创建成功")
	else:
		push_error("Logger: 无法创建日志文件 - %s"%_log_path)
		print("[Logger]:日志创建失败 - %s"%_log_path)
		return


# 日志记录核心
func _log(level:Level, message: String, source) -> void:
	if level < min_level:
		return
		
	var entry := {
		"level": level,
		"message": message,
		"source": str(source) if source else "",
		"time": Time.get_time_string_from_system(),
		"frame": Engine.get_process_frames(),
	}
	
	log_added.emit(entry)
	
	var level_str : String = Level.keys()[level]
	var source_str := "[%s]" % entry.source if not entry.source.is_empty() else ""
	print_rich("[color=gray][%s][/color] [%s] %s%s" % [entry.time, level_str, source_str, " " + message])
	
	pass
