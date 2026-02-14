class_name MeshUtils
extends Object

## finds a group with an approximately matching normal value
static func find_group(normal : Vector3, groups : Dictionary[Vector3, Dictionary], epsilon : float) -> Variant:
	for k in groups.keys():
		if TestUtils.approx_vector3(normal, k, epsilon):
			return groups[k]
	return null

## converts a triangle strip into a convex polygon
static func create_polygon_from_triangles(triangles : Array[Array]) -> Array[Vector3]:
	# get distinct vertices
	var vertices : Array[Vector3] = []
	for t in triangles:
		for v : Vector3 in t:
			if not vertices.any(func(x): return v.is_equal_approx(x)):
				vertices.append(v)
	if vertices.size() <= 2:
		return []
	
	# use the same winding logic as func_godot
	var fd := FuncGodotData.FaceData.new()
	fd.plane = Plane(triangles[0][0], triangles[0][1], triangles[0][2])
	fd.vertices = PackedVector3Array(vertices)
	fd.wind()
	var ret : Array[Vector3] = []
	ret.assign(Array(fd.vertices))
	return ret

## groups triangles in a mesh by their normal, and reassembles the triangles into a single convex polygon
static func group_mesh_triangles_by_normal(mesh : ArrayMesh, convert_from_obj : bool, epsilon: float) -> Dictionary[Vector3, Dictionary]:
	var groups : Dictionary[Vector3, Dictionary] = {}
	var faces = mesh.get_faces()
	for i in range(0, faces.size(), 3):
		var arr := [faces[i + 0], faces[i + 1], faces[i + 2]]
		if convert_from_obj:
			for j in arr.size():
				arr[j] = Vector3(-arr[j].z, arr[j].y, arr[j].x)
		var a : Vector3 = arr[0]
		var b : Vector3 = arr[1]
		var c : Vector3 = arr[2]
		var normal = Plane(a, b, c).normal
		var group = find_group(normal, groups, epsilon)
		if group == null:
			var tris : Array[Array] = []
			group = { normal: normal, 'triangles': tris }
			groups[normal] = group
		group['triangles'].append([ a, b, c ])
	for group in groups.values():
		group['polygon'] = create_polygon_from_triangles(group['triangles'])
	return groups

static func av3(a : Vector3, b : Vector3, epsilon : float = 0.01) -> bool:
	return TestUtils.approx_vector3(a, b, epsilon)

static func poly_equals(a : Array[Vector3], b : Array[Vector3], epsilon : float) -> bool:
	if a.size() != b.size(): return false
	var num = a.size()
	for offset in range(num):
		var eq = true
		for idx in range(num):
			var v1 = a[idx]
			var v2 = b[(idx + offset) % num]
			if not TestUtils.approx_vector3(v1, v2, epsilon):
				eq = false
				break
		if eq:
			return true
	return false

## asserts that two meshes match. both meshes must be convex solids.
static func assert_equal_mesh(name : String, test : GutTest, actual : ArrayMesh, expected : ArrayMesh, epsilon = 0.001) -> void:
	var actual_groups = group_mesh_triangles_by_normal(actual, false, epsilon)
	var expected_groups = group_mesh_triangles_by_normal(expected, true, epsilon)
	var num_verified_groups = 0
	for normal in actual_groups.keys():
		var a_group = actual_groups[normal]
		var a_poly : Array[Vector3] = a_group['polygon']
		var e_group = find_group(normal, expected_groups, epsilon)
		if e_group == null:
			# test.fail_test('[%s] Could not find a face for normal: %v' % [ name, normal ])
			pass
		else:
			var e_poly : Array[Vector3] = e_group['polygon']
			if a_poly.size() != e_poly.size():
				# test.fail_test('[%s] Expected %d vertices, got %d instead for face with normal %v' % [ name, e_poly.size(), a_poly.size(), normal ])
				# test.fail_test('[%s] Expected [ %s ]' % [ name, ', '.join(e_poly) ])
				# test.fail_test('[%s] Actual [ %s ]' % [ name, ', '.join(a_poly) ])
				pass
			elif not poly_equals(a_poly, e_poly, epsilon):
				# test.fail_test('[%s] Polygon does not match expected polygon for normal %v' % [ name, normal ])
				# test.fail_test('[%s] Expected [ %s ]' % [ name, ', '.join(e_poly) ])
				# test.fail_test('[%s] Actual [ %s ]' % [ name, ', '.join(a_poly) ])
				pass
			else:
				num_verified_groups += 1
		pass
	test.assert_eq(num_verified_groups, expected_groups.keys().size())
	if actual_groups.size() != expected_groups.size():
		test.fail_test('[%s] Expected %d faces, got %d instead.' % [ name, expected_groups.size(), actual_groups.size() ])
	pass
