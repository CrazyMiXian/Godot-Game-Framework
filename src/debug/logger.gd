extends  Node

enum Level{DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3}

## 配置项
# 日志最低等级
var min_level : Level = Level.DEBUG
# var buffer_size: int = 10
# 日志路径(自动生成)
var _log_path : String = ""
var _log_dir : String = "user://custom_logs/"
# 最大日志存在数量
const MAX_LOG_FILES := 5
# 内存中的日志条目（用于 DebugConsole 等实时查看）
var _entries: Array[Dictionary] = []

# 内部项
var _fully_initialized : bool = false

signal log_added(entry: Dictionary)


func _ready() -> void:
	_bootstrap()

# 分两步加载，保证日志全程可用
func _bootstrap() -> void:
	if _fully_initialized:
		return
	
	var err := DirAccess.make_dir_recursive_absolute(_log_dir)
	print("[Logger]: Log directory created - %s" % _log_dir)
	if err != OK:
		push_error("Logger: Failed to creat log directory - %s (ERROR CODE: %d)" % [_log_path, err])
		print("[Logger]: Failed to creat log directory，ERROR CODE: %d" % err)
		return
	print("[Logger]: Log directory ready")
	# 获取系统时间并给日志命名
	var time_str: String = Time.get_datetime_string_from_system()
	time_str = time_str.replace(":","-")
	_log_path = _log_dir + time_str + ".log"
	print("[Logger]: Creating log file - %s"%_log_path)
	var _file := FileAccess.open(_log_path,FileAccess.WRITE)
	if _file:
		_file.store_line("=========================")
		_file.store_line("Logger - %s" % Time.get_datetime_string_from_system())
		_file.store_line("=========================")
		print("[Logger]: Log file created successfully")
	else:
		push_error("Logger: Failed to create log file - %s"%_log_path)
		print("[Logger]: Failed to create log file - %s"%_log_path)
		return
	
	_clean_up_old_logs()
	print("[Logger]: Bootstrap complete, logging active (default level: DEBUG)")


# 初始化
func initialize() -> void:
	if _fully_initialized:
		LoggerGlobal.warn("Logger already initialized, skipping duplicate init", self.name)
		return
	
	load_config()
	_fully_initialized = true
	LoggerGlobal.info("Logger fully initialized, min_level=%s" % Level.keys()[min_level], self.name)
	

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
	
	_entries.append(entry)
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
		print_rich("[color=orange][%s][/color]" % "[Logger]: Log may be lost, attempting to recreate log file")
		if f: f.close()

	# 重新创建文件失败，则报错提示
	if _log_path.is_empty():
		if not _write_failed_warned:
			_write_failed_warned = true
			push_warning(" _log_path is empty, log write skipped (was initialize() not called?")
		return
	
	# 判断日志是否能够写入
	var file := FileAccess.open(_log_path, FileAccess.READ_WRITE)
	if file == null:
		if not _write_failed_warned:
			_write_failed_warned = true
			push_warning("[Logger]: Cannot open log file for writing - %s" % _log_path)
		return
	_write_failed_warned = false
	# 写入日志
	file.seek_end()
	file.store_line("[%s] [%s] %s: %s" % [entry.time, Level.keys()[entry.level], entry.source, entry.message])
	file.close()


# 读取配置文件
func load_config() -> void:
	var config_level : String = "debug"
	if $"/root".has_node("ConfigManager"):
		config_level = ConfigManager.get_value("debug.log_level", "debug")
		print("[Logger]: Loaded log_level from ConfigManager = %s" % config_level)
	else:
		print("[Logger]: ConfigManager not registered, using default log_level = debug")
	match config_level:
		"debug": min_level = Level.DEBUG
		"info": min_level = Level.INFO
		"warn": min_level = Level.WARN
		"error": min_level = Level.ERROR


# 清除旧日志文件
func _clean_up_old_logs() -> void:
	var dir := DirAccess.open(_log_dir)
	if dir == null:
		return
	
	# 获取文件夹内所有日志文件
	var log_files: Array[Dictionary] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name.ends_with(".log") and not dir.current_is_dir():
			var full_path := _log_dir + file_name
			log_files.append({
				"path": full_path,
				"modified": FileAccess.get_modified_time(full_path),
			})
		file_name = dir.get_next()
	dir.list_dir_end()
	
	# 最新的排最前
	log_files.sort_custom(func(a, b): return a.modified > b.modified)
	
	# 清除日志
	for i in range(MAX_LOG_FILES, log_files.size()):
		DirAccess.remove_absolute(log_files[i].path)
		print("[Logger]: Cleaned up old log file - %s" % log_files[i].path)

# 获取最近的日志条目（供 DebugConsole 使用）
func get_recent(count: int = 100) -> Array[Dictionary]:
	if _entries.size() <= count:
		return _entries.duplicate()
	return _entries.slice(-count)

# 获取当前日志文件的完整路径
func get_log_file_path() -> String:
	return _log_path
