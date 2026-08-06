extends Control

@onready var _progress_bar: ProgressBar = $ProgressBar
@onready var _color_rect: ColorRect = $ColorRect
@onready var _animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = false
	_color_rect.color.a = 0.0
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	SceneManager.load_progress.connect(_on_load_progess)

func _on_load_progess(progress:float):
	_progress_bar.value = progress

# 加载完毕
func fade_in(duration: float = 0.5) -> void:
	# print("IN")
	var tween := create_tween()
	tween.tween_property(_color_rect, "color:a", 0.0, duration)
	await tween.finished
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	self.visible = false

# 加载开始
func fade_out(duration: float = 0.5) -> void:
	# print("OUT")
	_progress_bar.value = 0.0
	self.visible = true
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # 阻止点击穿透
	var tween := create_tween()
	tween.tween_property(_color_rect, "color:a", 1.0, duration)
	await tween.finished
