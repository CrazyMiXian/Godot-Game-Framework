class_name ObjectPool
extends RefCounted

# 类的参数
var _scene: PackedScene
var _available: Array[Node] = []
var _active: Array[Node] = []
var _parent: Node
var _max_size: int
var _min_size: int

func _init(p_scene: PackedScene, p_parent: Node, p_preload: int = 10, p_max: int = 100, p_min: int = 10):
	_scene = p_scene
	_parent = p_parent
	_max_size = p_max
	_min_size = p_min

	# 预热
	for i in range(p_preload):
		_create_and_store()
	LoggerGlobal.info("Create object pool", self)
	

# 创建对象并隐藏
func _create_and_store() -> Node:
	var instance := _scene.instantiate()
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	if instance is Node2D or instance is Node3D:
		instance.visible = false
	_parent.add_child(instance)
	_available.append(instance)
	return instance

func acquire() -> Node:
	var instance: Node
	if _available.is_empty():
		var total := _available.size() + _active.size()
		if total >= _max_size:
			LoggerGlobal.warn("Object pool is full (%d)，can't create new object!" % _max_size, _parent)
			return null
		instance = _create_and_store()
	else:
		instance = _available.pop_back()

	_active.append(instance)
	# _parent.add_child(instance)
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	if instance is Node2D or instance is Node3D:
		instance.visible = true

	# 调用实例的初始化方法
	if instance.has_method("pool_initialize"):
		instance.pool_initialize()

	return instance


## 回收实例
func release(instance: Node) -> void:
	if not _active.has(instance):
		return

	_active.erase(instance)
	# 如果现存对象数量超出最小数量，则移除对象
	if _available.size() >= _min_size:
		instance.queue_free()
		return
	
	# 隐藏并停用对象
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	if instance is Node2D or instance is Node3D:
		instance.visible = false

	# 从场景树移除（放入池中）
	#if instance.get_parent():
	#	instance.get_parent().remove_child(instance)

	if instance.has_method("pool_reset"):
		instance.pool_reset()

	_available.append(instance)


## 回收所有活跃实例
func release_all() -> void:
	for instance in _active.duplicate():
		release(instance)


## 统计数据
func get_stats() -> Dictionary:
	return {
		"available": _available.size(),
		"active": _active.size(),
		"total": _available.size() + _active.size(),
		"max": _max_size,
		"hit_rate": _available.size() / float(max(1, _available.size() + _active.size())),
	}

''' 使用示例
# 在子弹管理器中
var bullet_pool: ObjectPool

func _ready():
    bullet_pool = ObjectPool.new(
        preload("res://entities/bullet.tscn"),
        self,   # 作为父节点
        p_preload = 20,
        p_max = 200
    )

func fire(pos: Vector2, dir: Vector2):
    var bullet := bullet_pool.acquire()
    if bullet:
        bullet.global_position = pos
        bullet.direction = dir

# 子弹命中后回收
func _on_bullet_hit(bullet: Node):
    bullet_pool.release(bullet)
'''
