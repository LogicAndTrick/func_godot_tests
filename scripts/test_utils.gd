class_name TestUtils
extends Object

static func approx_vector3(a : Vector3, b : Vector3, epsilon : float = 0.01) -> bool:
	var r : bool = false
	if abs(a.x - b.x) <= epsilon:
		if abs(a.y - b.y) <= epsilon:
			if abs(a.z - b.z) <= epsilon:
				r = true
	return r
