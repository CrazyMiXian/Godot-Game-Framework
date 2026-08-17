extends Button

@onready var label : Label =  $"../Label2"
@onready var locale_text: LocaleText = $"../Label2/Node"   # 场景里挂 LocaleText 的那个子节点

var amount : float = 10.0

func _ready() -> void:
	self.pressed.connect(test)

func test() -> void:
	amount += 1.0
	# 同步给 LocaleText 组件，而不是手动覆盖 label.text
	locale_text.placeholders = {"amount": amount}
	locale_text._update_text()
