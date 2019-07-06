extends Spatial
class_name Chunk

export var TERRAIN_HEIGHT = 48
export var TERRAIN_VERT = .25
export var GRASS_AMOUNT = 16
export var COLLIS = true
var mesh_instance
var noise
var x
var z
var chunk_size
var should_remove = false

func _init(noise, x, z, chunk_size):
	self.noise = noise
	self.x = x
	self.z = z
	self.chunk_size = chunk_size
	
func _ready():
	generate_chunk()
	#generate_water_layer()
	
func generate_terrain_chunk():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.subdivide_depth = chunk_size
	plane_mesh.subdivide_width = chunk_size
	
	var mesh_instance = MeshInstance.new()
	mesh_instance.mesh = plane_mesh
	
	add_child(mesh_instance)
	
func generate_chunk():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.subdivide_depth = chunk_size * TERRAIN_VERT
	plane_mesh.subdivide_width = chunk_size * TERRAIN_VERT
	plane_mesh.material = preload("res://materials/just_green.material")
	
	var surface_tool = SurfaceTool.new()
	var data_tool = MeshDataTool.new()
	surface_tool.create_from(plane_mesh, 0)
	var array_plane = surface_tool.commit()
	var error = data_tool.create_from_surface(array_plane, 0)
	var pool_array = PoolVector3Array()
	
	for i in range(data_tool.get_vertex_count()):
		var vertex = data_tool.get_vertex(i)
		
		vertex.y = noise.get_noise_3d(vertex.x + x, vertex.y, vertex.z + z) * TERRAIN_HEIGHT
		data_tool.set_vertex(i, vertex)
		pool_array.append(vertex)

	for s in range(array_plane.get_surface_count()):
		array_plane.surface_remove(s)
		
	data_tool.commit_to_surface(array_plane)
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.create_from(array_plane, 0)
	surface_tool.generate_normals()
	
	mesh_instance = MeshInstance.new()
	mesh_instance.mesh = surface_tool.commit()
	if COLLIS:
		mesh_instance.create_trimesh_collision()
	mesh_instance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	
	add_child(mesh_instance)
	generate_grass(pool_array)

func generate_grass(pool):
	var particles = CPUParticles.new()
	particles.set_emission_shape(3)
	particles.set_emission_points(pool)
	var mesh = preload("res://models/grass.mesh")
	particles.set_mesh(mesh)
	particles.set_gravity(Vector3(0,0,0))
	particles.set_lifetime(999)
	particles.set_one_shot(true)
	particles.set_amount(GRASS_AMOUNT)
	
	add_child(particles)
	
func generate_water_layer():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.subdivide_depth = chunk_size * TERRAIN_VERT
	plane_mesh.subdivide_width = chunk_size * TERRAIN_VERT
	plane_mesh.material = preload("res://materials/water2.material")
	

	var mesh_instance = MeshInstance.new()
	mesh_instance.mesh = plane_mesh
	mesh_instance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	if COLLIS:
		mesh_instance.create_trimesh_collision()
	
	add_child(mesh_instance)

