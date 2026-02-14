extends Node3D

func _ready() -> void:
	var meshInstance : MeshInstance3D = %entity_0_mesh_instance
	var arrayMesh : ArrayMesh = meshInstance.mesh
	var faces := arrayMesh.get_faces()
	print('%d faces in mesh.' % [ faces.size() / 3.0])
