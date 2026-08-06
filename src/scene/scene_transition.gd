extends Control

@onready var progress_bar: ProgressBar = $ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneManager.load_progress.connect(_on_load_progess)

func _on_load_progess(progress:float):
	progress_bar.value = progress

func fade_in() -> void:
	# print("IN")
	self.visible = false
	
func fade_out() -> void:
	# print("OUT")
	self.visible = true
