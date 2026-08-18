extends Node

## 语言切换信号
signal locale_changed(new_locale: String)

## 当前语言

var current_locale: String = "zh_CN":
	set(v):
		if current_locale != v:
			current_locale = v
			TranslationServer.set_locale(v)
			locale_changed.emit(v)

## 翻译数据 { "key": "翻译文本" }
var _translations: Dictionary = {}

## 支持的语言列表
var supported_locales: Array[String] = ["zh_CN", "en_US"]


func initialize() -> void:
	# 从配置读取上次使用的语言
	var saved = ConfigManager.get_value("language.locale", "zh_CN")
	#_load_translations()
	if saved not in supported_locales:
		saved = "zh_CN"
	current_locale = saved
	TranslationServer.set_locale(saved)
	locale_changed.emit(current_locale)

'''
func _load_translations() -> void:
	var path := "res://src/localization/data/%s.csv" % current_locale
	if not FileAccess.file_exists(path):
		LoggerGlobal.warn("语言文件不存在: %s" % path, self.name)
		_translations.clear()
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	_translations.clear()
	for line in text.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.is_empty() or trimmed.begins_with("#"):
			continue
		# 跳过表头
		if trimmed == "key,value":
			continue

		var parts := trimmed.split(",", true, 1)  # 只分割第一个逗号
		if parts.size() >= 2:
			var key := parts[0].strip_edges()
			var value := parts[1].strip_edges().replace("\\n", "\n")
			_translations[key] = value
			
	LoggerGlobal.info("Loaded %s successfully" % current_locale, self.name)
'''

## 翻译文本
func tr_text(key: String, placeholder_values: Dictionary = {}) -> String:
	var text := tr(key)
	if not placeholder_values.is_empty():
		text = text.format(placeholder_values)
	return text



## 全局快捷方法（在 gd_extensions.gd 中通过静态方法暴露）
static func get_text(key: String, values: Dictionary = {}) -> String:
	var text := TranslationServer.translate(key)
	if not values.is_empty():
		text = text.format(values)
	return text


# **翻译 CSV 格式** ：

'''csv
keys,en_US,zh_CN
ui.title,MyGame,我的游戏
ui.confirm,Confirm,确认
ui.cancel,Cancel,取消
ui.back,Back,返回
game.you_got_item,You received {count} {item_name},你获得了 {count} 个 {item_name}
combat.damage,Deal {amount} damage,造成了 {amount} 点伤害

'''
