extends Node

## 语言切换信号
signal locale_changed(new_locale: String)

## 当前语言
var current_locale: String = "zh_CN":
	set(v):
		if current_locale != v:
			current_locale = v
			_load_translations()
			locale_changed.emit(v)

## 翻译数据 { "key": "翻译文本" }
var _translations: Dictionary = {}

## 支持的语言列表
var supported_locales: Array[String] = ["zh_CN", "en_US"]


func initialize() -> void:
	# 从配置读取上次使用的语言
	current_locale = ConfigManager.get_value("language.locale", "zh_CN")
	LoggerGlobal.info("Loaded %s successfully" % current_locale, self.name)
	_load_translations()


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

		var parts := trimmed.split(",", true, 1)  # 只分割第一个逗号
		if parts.size() >= 2:
			var key := parts[0].strip_edges()
			var value := parts[1].strip_edges().replace("\\n", "\n")
			_translations[key] = value


## 翻译文本
func tr_text(key: String, placeholder_values: Dictionary = {}) -> String:
	var text : String = _translations.get(key, key)
	for placeholder in placeholder_values:
		text = text.replace("{%s}" % placeholder, str(placeholder_values[placeholder]))
	return text



## 全局快捷方法（在 gd_extensions.gd 中通过静态方法暴露）
static func _gloable(key: String, values: Dictionary = {}) -> String:
	return (Engine.get_main_loop() as SceneTree).root.get_node_or_null("LocaleManager").tr_text(key, values)


# **翻译 CSV 格式** (`zh_CN.csv`)：

'''csv
# 中文翻译表
key,value
ui.title,我的游戏
ui.confirm,确认
ui.cancel,取消
ui.back,返回
game.you_got_item,你获得了 {count} 个 {item_name}
combat.damage,造成了 {amount} 点伤害
'''
