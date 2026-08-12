class_name Easing
extends RefCounted

## 所有缓动函数均为静态方法，返回 t (0-1) 映射后的值
## 来源: https://easings.net/

static func ease_in_quad(t: float) -> float:
	return t * t

static func ease_out_quad(t: float) -> float:
	return t * (2.0 - t)

static func ease_in_out_quad(t: float) -> float:
	t *= 2.0
	if t < 1.0: return 0.5 * t * t
	t -= 1.0
	return -0.5 * (t * (t - 2.0) - 1.0)

static func ease_in_cubic(t: float) -> float:
	return t * t * t

static func ease_out_cubic(t: float) -> float:
	t -= 1.0
	return t * t * t + 1.0

static func ease_in_out_cubic(t: float) -> float:
	t *= 2.0
	if t < 1.0: return 0.5 * t * t * t
	t -= 2.0
	return 0.5 * (t * t * t + 2.0)

static func ease_out_elastic(t: float) -> float:
	if t == 0.0 or t == 1.0: return t
	return pow(2.0, -10.0 * t) * sin((t - 0.1) * 5.0 * PI) + 1.0

static func ease_out_bounce(t: float) -> float:
	if t < 1.0 / 2.75:
		return 7.5625 * t * t
	elif t < 2.0 / 2.75:
		t -= 1.5 / 2.75
		return 7.5625 * t * t + 0.75
	elif t < 2.5 / 2.75:
		t -= 2.25 / 2.75
		return 7.5625 * t * t + 0.9375
	else:
		t -= 2.625 / 2.75
		return 7.5625 * t * t + 0.984375
