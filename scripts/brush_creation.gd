class_name BrushCreation
extends Object

## hyperplane clipping using float32
static func hyperplane_single(generator : FuncGodotGeometryGenerator, brush : FuncGodotData.BrushData):
	var vertex_merge_distance: float = 1.0 / 32.0
	for face_index in brush.faces.size():
		var face: FuncGodotData.FaceData = brush.faces[face_index]
		face.vertices = generate_face_vertices_hyperplane_single(generator, brush, face_index, vertex_merge_distance)

## hyperplane clipping using float64
static func hyperplane_double(generator : FuncGodotGeometryGenerator, brush : FuncGodotData.BrushData):
	var vertex_merge_distance: float = 1.0 / 256.0
	for face_index in brush.faces.size():
		var face: FuncGodotData.FaceData = brush.faces[face_index]
		face.vertices = generate_face_vertices_hyperplane_double(generator, brush, face_index, vertex_merge_distance)

## plane intersection using float32 intersections & float32 hyperplanes
static func intersection_single(generator : FuncGodotGeometryGenerator, brush : FuncGodotData.BrushData):
	return _intersection(generator, brush, generate_face_vertices_hyperplane_single)

## plane intersection using float32 intersections & float64 hyperplanes
static func intersection_double(generator : FuncGodotGeometryGenerator, brush : FuncGodotData.BrushData):
	return _intersection(generator, brush, generate_face_vertices_hyperplane_double)

static func _intersection(generator : FuncGodotGeometryGenerator, brush : FuncGodotData.BrushData, hyperplane_callback : Callable):
	# this is a shortcut method - first we generate a cloud of points
	# from plane intersections. then we use the hyperplane_single method and snap each
	# point to the closest intersection from the point cloud. then we remove duplicate points in each face.
	var num := brush.faces.size()
	
	# each intersection can only apply to the 3 faces that have those planes.
	# use this to narrow down options during snapping
	var cloud : Array[Array] = []
	for i in range(num):
		cloud.append([])
	
	# calculate all intersection points
	for i in range(0, num - 2):
		for j in range(i, num - 1):
			for k in range(j, num):
				if i == j || j == k: continue
				var isect = brush.faces[i].plane.intersect_3(brush.faces[j].plane, brush.faces[k].plane)
				if isect != null and FuncGodotUtil.is_point_in_convex_hull(brush.planes, isect):
					cloud[i].append(isect)
					cloud[j].append(isect)
					cloud[k].append(isect)
	
	# do hyperplane method and then snap each point to a plane intersection point
	for face_index in brush.faces.size():
		var face: FuncGodotData.FaceData = brush.faces[face_index]
		var verts : PackedVector3Array = hyperplane_callback.call(generator, brush, face_index, 0)
		
		# snap verts to plane intersections
		face.vertices = PackedVector3Array()
		var candidates := cloud[face_index]
		for i in range(verts.size()):
			var v := verts[i]
			# get the candidate that is closest to the point
			var closest : Vector3 = candidates[0]
			var closest_dist := closest.distance_squared_to(v)
			for j in range(1, candidates.size()):
				var can : Vector3 = candidates[j]
				var can_dist := can.distance_squared_to(v)
				if can_dist < closest_dist:
					closest = can
					closest_dist = can_dist
			verts[i] = closest
		
		# Merge adjacent vertices that are equivalent
		var merged_winding : PackedVector3Array = PackedVector3Array()
		var prev_vtx : Vector3 = verts[0]
		merged_winding.append(prev_vtx)
		for i in range(1, verts.size()):
			var cur_vtx : Vector3 = verts[i]
			if !prev_vtx.is_equal_approx(cur_vtx):
				merged_winding.append(cur_vtx)
			prev_vtx = cur_vtx
		face.vertices = merged_winding

# -----

static func generate_face_vertices_hyperplane_single(generator : FuncGodotGeometryGenerator, brush : FuncGodotData.BrushData, face_index : int, vertex_merge_distance : float) -> PackedVector3Array:
	return generator.generate_face_vertices(brush, face_index, vertex_merge_distance)

static func generate_face_vertices_hyperplane_double(generator : FuncGodotGeometryGenerator, brush : FuncGodotData.BrushData, face_index : int, vertex_merge_distance : float) -> PackedVector3Array:
	return DoubleVector.generate_face_vertices(generator.hyperplane_size, brush, face_index, vertex_merge_distance)
