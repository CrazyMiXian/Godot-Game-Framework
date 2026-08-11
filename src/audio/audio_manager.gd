extends Node

## AudioBus 名称常量
enum Channel { MASTER, BGM, BGS, SFX, VOICE, UI }

const CHANNEL_BUS_NAMES := {
	Channel.MASTER: "Master",
	Channel.BGM: "BGM",
	Channel.BGS: "BGS",
	Channel.SFX: "SFX",
	Channel.VOICE: "Voice",
	Channel.UI: "UI",
}

## 频道路由：每个频道对应一个 AudioStreamPlayer
var _channels: Dictionary = {}
## BGM 播放器（专门处理淡入淡出和循环）
var _bgm_player: AudioStreamPlayer
var _bgm_playlist: Array[AudioStream] = []
var _bgm_index: int = 0

## SFX 池
var _sfx_pool: SFXPool

## 音量设置（0.0 - 1.0）
var master_volume: float = 1.0:
	set(v): _set_bus_volume(Channel.MASTER, v)
var bgm_volume: float = 1.0:
	set(v): _set_bus_volume(Channel.BGM, v)
var sfx_volume: float = 1.0:
	set(v): _set_bus_volume(Channel.SFX, v)


func initialize() -> void:
	# 创建频道路由
	for channel in CHANNEL_BUS_NAMES:
		var player := AudioStreamPlayer.new()
		player.name = "AudioChannel_%s" % CHANNEL_BUS_NAMES[channel]
		player.bus = CHANNEL_BUS_NAMES[channel]
		add_child(player)
		_channels[channel] = player

	_bgm_player = _channels[Channel.BGM]
	_sfx_pool = SFXPool.new(_channels[Channel.SFX])

	# 从配置恢复音量
	_load_volume_settings()


## 播放 BGM（带淡入）
func play_bgm(stream: AudioStream, fade_in_duration: float = 1.0) -> void:
	if _bgm_player.playing:
		await _fade_out_bgm(0.5)

	_bgm_player.stream = stream
	_bgm_player.play()

	# 淡入
	var tween := create_tween()
	tween.tween_method(_set_bgm_volume_db, -40.0, 0.0, fade_in_duration)


## 播放音效
func play_sfx(stream: AudioStream, pitch_variation: float = 0.0) -> AudioStreamPlayer:
	return _sfx_pool.play(stream, pitch_variation)


## 播放 UI 音效
func play_ui_sfx(stream: AudioStream) -> void:
	var player := _channels[Channel.UI] as AudioStreamPlayer
	player.stream = stream
	player.play()


## 设置频道音量（线性 0-1）
func set_channel_volume(channel: Channel, volume: float) -> void:
	_set_bus_volume(channel, volume)


func _set_bus_volume(channel: Channel, linear: float) -> void:
	var bus_name : String = CHANNEL_BUS_NAMES[channel]
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	# 线性转为 dB: 0.0 → -80dB, 1.0 → 0dB
	var db := linear_to_db(clampf(linear, 0.0, 1.0))
	AudioServer.set_bus_volume_db(bus_idx, db)


func _set_bgm_volume_db(db: float) -> void:
	var bus_idx := AudioServer.get_bus_index(CHANNEL_BUS_NAMES[Channel.BGM])
	AudioServer.set_bus_volume_db(bus_idx, db)


func _fade_out_bgm(duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(_set_bgm_volume_db, 0.0, -40.0, duration)
	await tween.finished
	_bgm_player.stop()


func _load_volume_settings() -> void:
	master_volume = ConfigManager.get_value("audio.master_volume", 1.0)
	bgm_volume = ConfigManager.get_value("audio.bgm_volume", 1.0)
	sfx_volume = ConfigManager.get_value("audio.sfx_volume", 1.0)
