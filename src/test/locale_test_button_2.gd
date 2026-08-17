extends Button

func _ready() -> void:
	self.pressed.connect(test)

func test() -> void:
	ConfigManager.set_value("language.locale", "en_US")
	ConfigManager.save_config()
	LocaleManager.current_locale = "en_US"
