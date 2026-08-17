extends Button

@onready var label : Label =  $"../Label2"

var amount : float = 10.0

func _ready() -> void:
	self.pressed.connect(test)

func test() -> void:
	label.text = LocaleManager.tr_text("combat.damage", {"amount": amount})
	amount += 1.0
