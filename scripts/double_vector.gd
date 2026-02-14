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
	func to_vector3() -> Vector3:
		return Vector3(snappedf(x, EPSILON), snappedf(y, EPSILON), snappedf(z, EPSILON))
	func dot(with : Vector3d) -> float:
		return x * with.x + y * with.y + z * with.z
	func distance_to(plane : Plane) -> float:
		return dot(Vector3d.from(plane.normal)) - plane.d
	func subtract(with : Vector3d) -> Vector3d:
		return Vector3d.new(x - with.x, y - with.y, z - with.z)
	func add(with : Vector3d) -> Vector3d:
		return Vector3d.new(x + with.x, y + with.y, z + with.z)
	func multiply(by : float) -> Vector3d:
		return Vector3d.new(x * by, y * by, z * by)
	func snappedf(step: float) -> Vector3d:
		return Vector3d.new(snappedf(x, step), snappedf(y, step), snappedf(z, step))
	func _to_string() -> String:
		return '(%.1f, %.1f, %.1f)' % [ x, y, z ]

const POINT_IN_PLANE_EPSILON : float = 0.00001

# Re-implementing the engine code at:
# https://github.com/godotengine/godot/blob/825ef2387f87de1c350696886e6c50b039204cef/core/math/geometry_3d.h#L480
static func clip_polygon(polygon : Array[Vector3d], plane : Plane) -> Array[Vector3d]:
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
				var den : float = Vector3d.from(plane.normal).dot(segment)
				var dist : float = v1.distance_to(plane) / den
				dist = -dist
				clipped.append(v1.add(segment.multiply(dist)))
		else:
			var v1 : Vector3d = polygon[index]
			if loc == LOC_INSIDE and location_cache[previous] == LOC_OUTSIDE:
				var v2 : Vector3d = polygon[previous]
				var segment : Vector3d = v1.subtract(v2)
				var den : float = Vector3d.from(plane.normal).dot(segment)
				var dist : float = v1.distance_to(plane) / den
				dist = -dist
				clipped.append(v1.add(segment.multiply(dist)))
			
			clipped.append(v1)
			
		previous = index
	return clipped

const _BrushData := FuncGodotData.BrushData

static func generate_base_winding(hyperplane_size : float, plane: Plane) -> Array[Vector3d]:
	var up := Vector3.UP
	if abs(plane.normal.dot(up)) > 0.9:
		up = Vector3.RIGHT

	var right: Vector3d = Vector3d.from(plane.normal.cross(up).normalized())
	var forward: Vector3d = Vector3d.from(right.to_vector3().cross(plane.normal).normalized())
	var centroid: Vector3d = Vector3d.from(plane.get_center())

	# construct oversized square on the plane to clip against
	
	var winding : Array[Vector3d] = []
	var h: float = hyperplane_size
	winding.append(centroid.add(right.multiply( h)).add(forward.multiply( h)))
	winding.append(centroid.add(right.multiply(-h)).add(forward.multiply( h)))
	winding.append(centroid.add(right.multiply(-h)).add(forward.multiply(-h)))
	winding.append(centroid.add(right.multiply( h)).add(forward.multiply(-h)))
	return winding

static func generate_face_vertices(hyperplane_size : float, brush: _BrushData, face_index: int, vertex_merge_distance: float = 0.0) -> PackedVector3Array:
	var plane: Plane = brush.faces[face_index].plane
	
	# Generate initial square polygon to clip other planes against
	var winding: Array[Vector3d] = generate_base_winding(hyperplane_size, plane)

	for other_face_index in brush.faces.size():
		if other_face_index == face_index:
			continue
		
		# NOTE: This may need to be recentered to the origin, then moved back to the correct face position
		# This problem may arise from floating point inaccuracy, given a large enough initial brush
		winding = clip_polygon(winding, brush.faces[other_face_index].plane)
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
