extends Button

func _ready() -> void:
	self.pressed.connect(test)

func test() -> void:
	ConfigManager.set_value("language.locale", "zh_CN")
	ConfigManager.save_config()
	LocaleManager.current_locale = "zh_CN"
