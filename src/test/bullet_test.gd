extends Node2D

var direction: Vector2
var speed: float = 300.0


## 每帧移动 + 边界检测
func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	
	# 超出安全区域 → 自动回收
	if global_position.x < -100 or global_position.x > 1200 \
	   or global_position.y < -100 or global_position.y > 900:
		_recycle()

## 碰撞检测（假设子弹有 Area2D 子节点）
func _on_area_entered(body: Node2D) -> void:
	_recycle()

## 统一回收入口
func _recycle():
	EventBus.emit("bullet_realease", self)
