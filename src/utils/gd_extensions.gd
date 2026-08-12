class_name GDExtentions
extends RefCounted

## 为数组增加扩展方法（通过静态方法实现，因为 GDScript 不支持直接扩展）

static func array_random(arr: Array):
	if arr.is_empty():
		return null
	return arr[randi() % arr.size()]


static func array_remove_all(arr: Array, item) -> void:
	var i := arr.size() - 1
	while i >= 0:
		if arr[i] == item:
			arr.remove_at(i)
		i -= 1


## Vector2 工具
static func v2_to_angle(v: Vector2) -> float:
	return v.angle()


static func v2_from_angle(angle: float, length: float = 1.0) -> Vector2:
	return Vector2(cos(angle), sin(angle)) * length


static func v2_rotate_around(point: Vector2, pivot: Vector2, angle: float) -> Vector2:
	var diff := point - pivot
	return pivot + Vector2(
		diff.x * cos(angle) - diff.y * sin(angle),
		diff.x * sin(angle) + diff.y * cos(angle)
	)


## 时间工具
static func delay(tree: SceneTree, seconds: float) -> Signal:
	return tree.create_timer(seconds).timeout


static func wait_frames(tree: SceneTree, frames: int) -> void:
	for i in range(frames):
		await tree.process_frame
