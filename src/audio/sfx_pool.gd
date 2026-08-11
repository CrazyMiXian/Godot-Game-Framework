class_name SFXPool
extends RefCounted

var _parent: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _pool_size: int = 16
var _active: Array[AudioStreamPlayer] = []


func _init(p_parent: AudioStreamPlayer, p_size: int = 16):
	_parent = p_parent
	_pool_size = p_size
	_pre_create()
	
func _pre_create() -> void:
	for i in range(_pool_size):
		var player := AudioStreamPlayer.new()
		player.bus = _parent.bus
		player.finished.connect(_on_finished.bind(player))
		_parent.add_child(player)
		_pool.append(player)


func play(stream: AudioStream, pitch_variation: float = 0.0) -> AudioStreamPlayer:
	var player: AudioStreamPlayer

	if _pool.is_empty():
	# 池耗尽，创建临时播放器
		player = AudioStreamPlayer.new()
		player.bus = _parent.bus
		player.finished.connect(_on_finished.bind(player))
		_parent.add_child(player)
	else:
		player = _pool.pop_back()

	player.stream = stream
	# 随机微调音高（增加音效多样性）
	if pitch_variation > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	else:
		player.pitch_scale = 1.0

	player.play()
	_active.append(player)
	return player


func _on_finished(player: AudioStreamPlayer) -> void:
	_active.erase(player)
	player.stream = null
	if _pool.size() < _pool_size:
		_pool.append(player)
	else:
		player.queue_free()
