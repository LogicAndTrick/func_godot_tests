class_name DoubleVector
extends Object

class Vector3d:
	const EPSILON : float = 0.0001
	var x : float
	var y : float
	var z : float
	func _init(x_ : float, y_ : float, z_ : float) -> void:
		x = x_
		y = y_
		z = z_
	static func from(vec : Vector3) -> Vector3d:
		return Vector3d.new(vec.x, vec.y, vec.z)
	static func from_packedfloat64array(arr : PackedFloat64Array) -> Vector3d:
		return Vector3d.new(arr[0], arr[1], arr[2])
	func to_vector3() -> Vector3:
		return Vector3(snappedf(x, EPSILON), snappedf(y, EPSILON), snappedf(z, EPSILON))
	func dot(with : Vector3d) -> float:
		return x * with.x + y * with.y + z * with.z
	func cross(with : Vector3d) -> Vector3d:
		return Vector3d.new(
			(y * with.z) - (z * with.y),
			(z * with.x) - (x * with.z),
			(x * with.y) - (y * with.x)
		)
	func distance_to(plane : Planed) -> float:
		return dot(plane.normal) - plane.d
	func subtract(with : Vector3d) -> Vector3d:
		return Vector3d.new(x - with.x, y - with.y, z - with.z)
	func add(with : Vector3d) -> Vector3d:
		return Vector3d.new(x + with.x, y + with.y, z + with.z)
	func multiply(by : float) -> Vector3d:
		return Vector3d.new(x * by, y * by, z * by)
	func divide(by : float) -> Vector3d:
		return Vector3d.new(x / by, y / by, z / by)
	func snappedf(step: float) -> Vector3d:
		return Vector3d.new(snappedf(x, step), snappedf(y, step), snappedf(z, step))
	func _to_string() -> String:
		return '(%.1f, %.1f, %.1f)' % [ x, y, z ]
	func to_string_precise() -> String:
		return '(%.6f, %.6f, %.6f)' % [ x, y, z ]
	func length_squared() -> float:
		return x*x + y*y + z*z
	func normalized() -> Vector3d:
		var lengthsq := length_squared()
		if lengthsq == 0:
			return Vector3d.new(0, 0, 0)
		else:
			var length = sqrt(lengthsq)
			return Vector3d.new(x / length, y / length, z / length)
	func normalize() -> void:
		var lengthsq := length_squared()
		if lengthsq == 0:
			x = 0
			y = 0
			z = 0
		else:
			var length = sqrt(lengthsq)
			x /= length
			y /= length
			z /= length
	func distance_squared_to(v : Vector3) -> float:
		return Vector3d.from(v).subtract(self).length_squared()

class Planed:
	var d : float
	var normal : Vector3d
	func _init(normal_ : Vector3d, d_: float) -> void:
		normal = normal_
		d = d_
	static func from_points(p1 : Vector3d, p2 : Vector3d, p3 : Vector3d) -> Planed:
		var normal_ := p1.subtract(p3).cross(p1.subtract(p2))
		normal_.normalize()
		var d_ := normal_.dot(p1)
		return Planed.new(normal_, d_)
	static func from_packedfloat64array_array(arr : Array[PackedFloat64Array]) -> Planed:
		var a := Vector3d.from_packedfloat64array(arr[0])
		var b := Vector3d.from_packedfloat64array(arr[1])
		var c := Vector3d.from_packedfloat64array(arr[2])
		return from_points(a, b, c)
	static func from(plane : Plane) -> Planed:
		return Planed.new(Vector3d.from(plane.normal), plane.d)
	func distance_to(point : Vector3d) -> float:
		return normal.dot(point) - d;
	func get_center() -> Vector3d:
		return normal.multiply(d)
	func intersect_3(plane1 : Planed, plane2 : Planed) -> Variant:
		var plane0 := self
		var normal0 := plane0.normal
		var normal1 := plane1.normal
		var normal2 := plane2.normal
		var denom : float = normal0.cross(normal1).dot(normal2)
		if is_zero_approx(denom):
			return null
		var a := normal1.cross(normal2)	.multiply(plane0.d)
		var b := normal2.cross(normal0).multiply(plane1.d)
		var c := normal0.cross(normal1).multiply(plane2.d)
		return (a.add(b).add(c)).divide(denom)
		

const POINT_IN_PLANE_EPSILON : float = 0.00001

# Re-implementing the engine code at:
# https://github.com/godotengine/godot/blob/825ef2387f87de1c350696886e6c50b039204cef/core/math/geometry_3d.h#L480
static func clip_polygon(polygon : Array[Vector3d], plane : Planed) -> Array[Vector3d]:
	const LOC_INSIDE : int = 1;
	const LOC_BOUNDARY : int = 0;
	const LOC_OUTSIDE : int = -1;
	
	if polygon.is_empty():
		return polygon
	
	var location_cache : Array[int] = []
	var inside_count : int = 0
	var outside_count : int = 0
	
	for i in polygon.size():
		var v : Vector3d = polygon[i]
		var dist : float = v.distance_to(plane)
		if dist < -POINT_IN_PLANE_EPSILON:
			location_cache.append(LOC_INSIDE)
			inside_count += 1
		elif dist > POINT_IN_PLANE_EPSILON:
			location_cache.append(LOC_OUTSIDE)
			outside_count += 1
		else:
			location_cache.append(LOC_BOUNDARY)
	
	if outside_count == 0:
		return polygon
	elif inside_count == 0:
		return []
	
	var previous : int = polygon.size() - 1
	var clipped : Array[Vector3d] = []
	for index in polygon.size():
		var loc : int = location_cache[index]
		if loc == LOC_OUTSIDE:
			if location_cache[previous] == LOC_INSIDE:
				var v1 : Vector3d = polygon[previous]
				var v2 : Vector3d = polygon[index]
				
				var segment : Vector3d = v1.subtract(v2)
				var den : float = plane.normal.dot(segment)
				var dist : float = v1.distance_to(plane) / den
				dist = -dist
				clipped.append(v1.add(segment.multiply(dist)))
		else:
			var v1 : Vector3d = polygon[index]
			if loc == LOC_INSIDE and location_cache[previous] == LOC_OUTSIDE:
				var v2 : Vector3d = polygon[previous]
				var segment : Vector3d = v1.subtract(v2)
				var den : float = plane.normal.dot(segment)
				var dist : float = v1.distance_to(plane) / den
				dist = -dist
				clipped.append(v1.add(segment.multiply(dist)))
			
			clipped.append(v1)
			
		previous = index
	return clipped

const _BrushData := FuncGodotData.BrushData

static func generate_base_winding(hyperplane_size : float, plane: Planed) -> Array[Vector3d]:
	var up := Vector3d.from(Vector3.UP)
	if abs(plane.normal.dot(up)) > 0.9:
		up = Vector3d.from(Vector3.RIGHT)

	var right: Vector3d = plane.normal.cross(up).normalized()
	var forward: Vector3d = right.cross(plane.normal).normalized()
	var centroid: Vector3d = plane.get_center()

	# construct oversized square on the plane to clip against
	
	var winding : Array[Vector3d] = []
	var h: float = hyperplane_size
	winding.append(centroid.add(right.multiply( h)).add(forward.multiply( h)))
	winding.append(centroid.add(right.multiply(-h)).add(forward.multiply( h)))
	winding.append(centroid.add(right.multiply(-h)).add(forward.multiply(-h)))
	winding.append(centroid.add(right.multiply( h)).add(forward.multiply(-h)))
	return winding

static func generate_face_vertices(hyperplane_size : float, brush: _BrushData, face_index: int, vertex_merge_distance: float = 0.0) -> PackedVector3Array:
	var plane := Planed.from_packedfloat64array_array(brush.faces[face_index].parsed_plane_points)
	
	# Generate initial square polygon to clip other planes against
	var winding: Array[Vector3d] = generate_base_winding(hyperplane_size, plane)

	for other_face_index in brush.faces.size():
		if other_face_index == face_index:
			continue
		
		# NOTE: This may need to be recentered to the origin, then moved back to the correct face position
		# This problem may arise from floating point inaccuracy, given a large enough initial brush
		var other_plane := Planed.from_packedfloat64array_array(brush.faces[other_face_index].parsed_plane_points)
		winding = clip_polygon(winding, other_plane)
		if winding.is_empty():
			break
	
	if vertex_merge_distance > 0:
		var merged_winding : Array[Vector3d] = []
		var prev_vtx : Vector3d = winding[0].snappedf(vertex_merge_distance)
		merged_winding.append(prev_vtx)
		for i in range(1, winding.size()):
			var cur_vtx : Vector3d = winding[i].snappedf(vertex_merge_distance)
			if prev_vtx != cur_vtx:
				merged_winding.append(cur_vtx)
			prev_vtx = cur_vtx
		winding = merged_winding
	
	var result : PackedVector3Array = PackedVector3Array()
	for v in winding:
		result.append(v.to_vector3())
	return result

const _VERTEX_EPSILON: float = 0.0008

static func is_point_in_convex_hull(planes: Array[Planed], vertex: Vector3d) -> bool:
	for plane in planes:
		var distance: float = plane.normal.dot(vertex) - plane.d
		if distance > _VERTEX_EPSILON:
			return false
	return true
