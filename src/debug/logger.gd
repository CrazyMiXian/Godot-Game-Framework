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
	debug("Hello World", self.name)
	info("Hello World", self.name)
	warn("Hello World", self.name)
	error("Hello World", self.name)

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
		_file.store_line("Logger - %s" % Time.get_datetime_string_from_system())
		_file.store_line("=========================")
		print("[Logger]:日志创建成功")
	else:
		push_error("Logger: 无法创建日志文件 - %s"%_log_path)
		print("[Logger]:日志创建失败 - %s"%_log_path)
		return

func debug(message:String, source = null) -> void:
	_log(Level.DEBUG, message, source)
	
func info(message:String, source = null) -> void:
	_log(Level.INFO, message, source)
	
func warn(message:String, source = null) -> void:
	_log(Level.WARN, message, source)
	
func error(message:String, source = null) -> void:
	_log(Level.ERROR, message, source)

# 日志记录核心
func _log(level:Level, message: String, source) -> void:
	if level < min_level:
		return
		# 信息字典
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
	
	_write_to_file(entry)
	
var _write_failed_warned: bool = false

func _write_to_file(entry:Dictionary) -> void:
	# 如果文件被外部删除，重新创建文件
	if not FileAccess.file_exists(_log_path):
		var f := FileAccess.open(_log_path, FileAccess.WRITE)
		print_rich("[color=orange][%s][/color]" % "[Logger]:日志可能丢失，尝试重新创建日志")
		if f: f.close()

	# 重新创建文件失败，则报错提示
	if _log_path.is_empty():
		if not _write_failed_warned:
			_write_failed_warned = true
			push_warning("[Logger]:_log_path为空，日志写入已跳过(initialize()是否未被调用？)")
		return
	
	# 判断日志是否能够写入
	var file := FileAccess.open(_log_path, FileAccess.READ_WRITE)
	if file == null:
		if not _write_failed_warned:
			_write_failed_warned = true
			push_warning("[Logger]:无法打开日志进行写入 - %s" % _log_path)
		return
	_write_failed_warned = false
	# 写入日志
	file.seek_end()
	file.store_line("[%s] [%s] %s: %s" % [entry.time, Level.keys()[entry.level], entry.source, entry.message])
	file.close()
