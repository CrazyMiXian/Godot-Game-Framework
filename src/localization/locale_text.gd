class_name LocaleText
extends Node

@export var translation_key: String = ""
@export var placeholders: Dictionary = {}

var _parent: Control


func _ready() -> void:
	_parent = get_parent() as Control
	if _parent == null:
		return

	_update_text()
	LocaleManager.locale_changed.connect(_update_text)


func _update_text(_new_locale: String = "") -> void:
	if _parent == null or translation_key.is_empty():
		return

	var text := LocaleManager.tr_text(translation_key, placeholders)
	# 自动匹配父节点的文本属性
	if _parent is Label:
		(_parent as Label).text = text
	elif _parent is Button:
		(_parent as Button).text = text
	elif _parent is LineEdit:
		(_parent as LineEdit).placeholder_text = text
