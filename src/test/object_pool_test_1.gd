extends Node


var bullet_pool: ObjectPool

func _ready():
	bullet_pool = ObjectPool.new(
		load("res://entities/bullet.tscn") as PackedScene,
		self,   # 作为父节点
		20,
		200
	)
	EventBus.on("bullet_realease", Callable(self, "_bullet_realease"))
	for i in 100:
		if not _firing:
			_firing = true
			fire(Vector2(200, 200), Vector2(0.5, 0.5))
			await get_tree().create_timer(0.05).timeout
			_firing = false
	
var _firing : bool = false

func _process(delta: float) -> void:
	pass

func fire(pos: Vector2, dir: Vector2):
	var bullet := bullet_pool.acquire()
	if bullet:
		bullet.global_position = pos
		print("Fire!")
		bullet.direction = dir

# 子弹命中后回收
func _bullet_realease(bullet: Node):
	bullet_pool.release(bullet)
