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


# -----

static func generate_face_vertices_hyperplane_single(generator : FuncGodotGeometryGenerator, brush : FuncGodotData.BrushData, face_index : int, vertex_merge_distance : float) -> PackedVector3Array:
	return generator.generate_face_vertices(brush, face_index, vertex_merge_distance)

static func generate_face_vertices_hyperplane_double(generator : FuncGodotGeometryGenerator, brush : FuncGodotData.BrushData, face_index : int, vertex_merge_distance : float) -> PackedVector3Array:
	return DoubleVector.generate_face_vertices(generator.hyperplane_size, brush, face_index, vertex_merge_distance)
