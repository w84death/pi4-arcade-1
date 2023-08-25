extends Node3D

var noise
@export var chunk_size = 512
@export var chunk_amount = 8
@export var n_seed = 7
@export var n_octaves = 3
@export var n_period = 180
@export var n_persistence = 0.4
@export var n_lacunarity = 4

var chunks = {}
var unready_chunks = {}
var thread

func _ready():
	randomize()
	noise = FastNoiseLite.new()
	noise.seed = n_seed
	noise.frequency = 0.001
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_gain = 0.01
	noise.fractal_lacunarity = 4
	
	thread = Thread.new()
	
func add_chunk(x, z):
	var key = str(x) + "," + str(z)
	if chunks.has(key) or unready_chunks.has(key):
		return
	
	if not thread.is_started():
		thread.start(Callable(self, "load_chunk").bind([thread, x, z]))
		unready_chunks[key] = 1

func load_chunk(arr):
	var thread = arr[0]
	var x = arr[1]
	var z = arr[2]
	
	var chunk = Chunk.new(noise, x * chunk_size, z * chunk_size, chunk_size)
	chunk.position = Vector3(x * chunk_size, 0, z * chunk_size)
	
	call_deferred("load_done", chunk, thread)
	
func load_done(chunk, thread):
	add_child(chunk)
	var key = str(chunk.x / chunk_size) + "," + str(chunk.z / chunk_size)
	chunks[key] = chunk
	unready_chunks.erase(key)
	thread.wait_to_finish()
	if $player.flying and chunks.size() >= chunk_amount * chunk_amount:
		$HUD/loading.hide()
		$player.flying = false
	
func get_chunk(x, z):
	var key = str(x) + "," + str(z)
	
	if chunks.has(key):
		return chunks.get(key)
		
	return null
	
func _process(delta):
	update_chunks()
	clean_up_chunks()
	reset_chunks()
	
func update_chunks():
	var player_translation = $player.position
	var p_x = int(player_translation.x) / chunk_size
	var p_z = int(player_translation.z) / chunk_size
	
	for x in range(p_x - chunk_amount * 0.5, p_x + chunk_amount * 0.5):
		for z in range(p_z - chunk_amount * 0.5, p_z + chunk_amount * 0.5):
			add_chunk(x, z)
			var chunk = get_chunk(x, z)
			if chunk != null:
				chunk.should_remove = false

func clean_up_chunks():
	for key in chunks:
		var chunk = chunks[key]
		if chunk.should_remove:
			chunk.queue_free()
			chunks.erase(key)
	
func reset_chunks():
	for key in chunks:
		chunks[key].should_remove = true
	
	
	
	
	
	
	
