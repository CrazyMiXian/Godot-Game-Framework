class_name RandomUtils
extends RefCounted

## 加权随机选择
static func weighted_choice(weights: Dictionary) -> String:
	# weights: { "sword": 30, "shield": 20, "potion": 50 }
	var total := 0.0
	for key in weights:
		total += weights[key]

	var roll := randf() * total
	var cumulative := 0.0
	for key in weights:
		cumulative += weights[key]
		if roll <= cumulative:
			return key
	return weights.keys()[0]


## 随机打乱数组（Fisher-Yates）
static func shuffle(array: Array) -> Array:
	var result := array.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var temp = result[i]
		result[i] = result[j]
		result[j] = temp
	return result


## 正态分布随机（Box-Muller）
static func normal_random(mean: float = 0.0, std_dev: float = 1.0) -> float:
	var u1 := randf()
	var u2 := randf()
	var z := sqrt(-2.0 * log(maxf(u1, 0.0001))) * cos(2.0 * PI * u2)
	return mean + z * std_dev
