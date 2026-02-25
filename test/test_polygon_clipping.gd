extends GutTest

var map_settings = preload('res://test_map_settings.tres')
var hyperplane_size = 16384

var icosahedron_first_face_expected_verts : Array[Vector3] = [
	Vector3( 58.753141626913774, 24, 50.147360205302505 ),
	Vector3( 48, 24, 88 ),
	Vector3( 61.7507764265583, -12, 65.75077655274063 ),
];

func _do_test_face(
	brush : FuncGodotData.BrushData,
	face_index : int,
	generate_vertices : Callable,
	vertex_merge_distance : float,
	expected_verts : Array[Vector3],
	allowed_tolerance : float
) -> float:
	var generator := FuncGodotGeometryGenerator.new(map_settings, hyperplane_size)
	var entity := FuncGodotData.EntityData.new()
	entity.brushes.append(brush)
	generator.entity_data.append(entity)
	
	var actual_verts : PackedVector3Array = generate_vertices.call(generator, brush, face_index, vertex_merge_distance)
	
	var worst_tolerance : float = 0
	assert_eq(actual_verts.size(), expected_verts.size(), 'Incorrect number of vertices.')
	for av in actual_verts:
		# get the closest vert
		expected_verts.sort_custom(
			func(v1 : Vector3, v2 : Vector3) -> bool:
				var d1 = v1.distance_squared_to(av)
				var d2 = v2.distance_squared_to(av)
				return d1 < d2
		)
		var ev := expected_verts[0]
		var dist := ev.distance_to(av)
		if dist > worst_tolerance: worst_tolerance = dist
		assert_lt(dist, allowed_tolerance, 'Vertex not within allowed tolerance.')
	return worst_tolerance

var algorithms = [
	'hyperplane_single',
	'hyperplane_double',
];
func test_icosahadron_first_face(algorithm : String = use_parameters(algorithms)):
	var parser := FuncGodotParser.new()
	var data := parser.parse_map_data('res://resources/brushes/icosahedron.map', map_settings)
	
	var brush := data.entities[0].brushes[0]
	var face_index := 0
	var gen := Callable(BrushCreation, 'generate_face_vertices_' + algorithm)
	var vertex_merge_distance : float = 0.0 if algorithm.contains('double') else 1.0 / 256.0
	var expected := icosahedron_first_face_expected_verts
	var tolerance := 0.01
	
	var worst_tolerance = _do_test_face(brush, face_index, gen, vertex_merge_distance, expected, tolerance)
	print('[%s] Worst tolerance is: %f' % [algorithm, worst_tolerance])
	pass
