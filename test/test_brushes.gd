extends GutTest

# inverse scale factor is 1, so we use an unscaled hyperplane as well (default of 512 * 32 = 16384)
var map_settings = preload('res://test_map_settings.tres')
var hyperplane_size = 16384

var algorithms = [
	'hyperplane_single',
	'hyperplane_double',
];

func assemble_brush_parameters():
	var params : Array = [];
	var brush_files := DirAccess.get_files_at('res://resources/brushes')
	for a in algorithms:
		for b in brush_files:
			var ext := b.get_extension()
			if ext == 'map':
				params.append([a, b.get_file().get_basename()])
	return use_parameters(params)

func test_brushes(params = assemble_brush_parameters()):
	# setup
	var algorithm = params[0]
	var brush = params[1]
	var obj : ArrayMesh = load('res://resources/brushes/' + brush + '.obj')
	
	var timing = {
		'brush': brush,
		'algorithm': algorithm
	};
	
	# create a generator
	var parser := FuncGodotParser.new()
	var parse_data: FuncGodotData.ParseData = parser.parse_map_data('res://resources/brushes/' + brush + '.map', map_settings)
	var generator := FuncGodotGeometryGenerator.new(map_settings, hyperplane_size)
	generator.entity_data = parse_data.entities
	
	# preform pre-algorithm setup
	var texture_map: Array[Dictionary] = FuncGodotUtil.build_texture_map(generator.entity_data, map_settings)
	generator.texture_materials = texture_map[0]
	generator.texture_sizes = texture_map[1]
	
	# call the implementation of the brush creation algorithm
	timing['start'] = Time.get_ticks_usec()
	var callable = Callable(BrushCreation, algorithm)
	callable.call(generator, generator.entity_data[0].brushes[0])
	timing['end'] = Time.get_ticks_usec()
	
	# pre-check for invalid faces - to avoid spamming the debugger message log
	var invalid = [];
	for f in generator.entity_data[0].brushes[0].faces:
		if f.vertices.size() <= 2:
			invalid.append(f)
	if !invalid.is_empty():
		fail_test('[%s] %d face(s) with fewer than 3 vertices - the brush is not valid.' % [ algorithm + ':' + brush, invalid.size() ])
		return
	
	# do the remaining brush creation steps
	set_normals_and_tangents(generator.entity_data[0].brushes[0])
	generator.determine_entity_origins(0)
	generator.wind_entity_faces(0)
	generator.generate_entity_surfaces(0)
	
	# compare the generated result with the imported .obj
	var mesh = generator.entity_data[0].mesh
	MeshUtils.assert_equal_mesh(algorithm + ':' + brush, self, mesh, obj, 0.001)
	
	# finish
	timing['duration'] = timing['end'] - timing['start']
	if !timings.has(brush): timings[brush] = []
	timings[brush].append(timing)

# -------------------

static func set_normals_and_tangents(brush : FuncGodotData.BrushData) -> void:
	for face_index in brush.faces.size():
		var face: FuncGodotData.FaceData = brush.faces[face_index]
		
		face.normals.resize(face.vertices.size())
		face.normals.fill(face.plane.normal)
		
		var tangent: PackedFloat32Array = FuncGodotUtil.get_face_tangent(face)
		
		# convert into OpenGL coordinates
		for i in face.vertices.size():
			face.tangents.append(tangent[1]) # Y
			face.tangents.append(tangent[2]) # Z
			face.tangents.append(tangent[0]) # X
			face.tangents.append(tangent[3]) # W

# -------------------

var timings = {}

func after_all():
	print('----------')
	print(' timings: ')
	print('----------')
	for k in timings.keys():
		print(k)
		for t in timings[k]:
			prints(' > ', t['algorithm'].rpad(40), ':', t['duration'] / 1000.0)
		print('')
	print('----------')
	pass
