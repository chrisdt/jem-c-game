extends Node2D

# Shared by all planets; the historical file name remains for project links.
const OUTER_REGIONS = preload("res://outer_regions.gd")
const AMBIENCE = preload("res://environment/region_ambience.gd")
const LAVA_FLOW = preload("res://shaders/lava_flow.gdshader")
const EARTH_WATER = preload("res://environment/earth_water.gd")
const AMBIENT_LIFE = preload("res://environment/ambient_life.gd")

var REGIONS = preload("res://earth_regions.gd")
const TREE: PackedScene = preload("res://environment/wind_tree.tscn")
const PLANT: PackedScene = preload("res://environment/wind_plant.tscn")
const MAX_TEXTURES := 3
const MAX_REQUESTS := 2
const PREFETCH_DISTANCE := 700.0
var textures: Dictionary = {}
var used_at: Dictionary = {}
var desired: Dictionary = {}
var jobs: Dictionary = {}
var queue: Array[String] = []
var decode_queue: Array[Dictionary] = []
var failures: Dictionary = {}
var active_key := ""
var pinned := ""
var scenery: Node2D
var clock := 0.0
var peak_textures := 0
var peak_jobs := 0
var network_requests := 0
var texture_loads := 0
var evictions := 0
var max_decode_ms := 0.0
var max_install_ms := 0.0

func is_ready(key: String) -> bool:
	return not REGIONS.ASSETS.has(key) or textures.has(key)

func request(key: String, retry := false) -> void:
	if not REGIONS.ASSETS.has(key):
		return
	desired[key] = true
	if textures.has(key):
		used_at[key] = clock
		return
	if retry:
		failures.erase(key)
	if failures.has(key) and clock - float(failures[key]) < 5:
		return
	if jobs.has(key) or queue.has(key):
		return
	for decoded in decode_queue:
		if decoded.key == key:
			return
	queue.append(key)

func prepare(region: int, cave: bool, player: Vector2) -> void:
	var candidates: Array[Dictionary] = []
	if not cave:
		for link in REGIONS.LINKS[region]:
			var distance := player.distance_to(REGIONS.portal(region,link.side))
			if distance < PREFETCH_DISTANCE:
				candidates.append({"key":REGIONS.key(link.target,false),"distance":distance})
		if REGIONS.has_mine(region):
			var distance := player.distance_to(REGIONS.MINE_ENTRANCES[region])
			if distance < PREFETCH_DISTANCE:
				candidates.append({"key":REGIONS.key(region,true),"distance":distance})
	elif player.distance_to(REGIONS.MINE_EXITS[region]) < PREFETCH_DISTANCE:
		candidates.append({"key":REGIONS.key(region,false),"distance":0.0})
	candidates.sort_custom(func(a,b): return a.distance < b.distance)
	desired.clear()
	if not active_key.is_empty(): desired[active_key] = true
	if not pinned.is_empty(): desired[pinned] = true
	var count := 0
	for candidate in candidates:
		if not REGIONS.ASSETS.has(candidate.key): continue
		request(candidate.key)
		count += 1
		if count == 2: break
	# Release slow downloads left behind by the player, so a requested trail
	# never waits behind two irrelevant HTTP timeouts on a poor connection.
	for key in jobs.keys():
		if not desired.has(key) and jobs[key].has("http"):
			jobs[key].http.cancel_request()
			jobs[key].http.queue_free()
			jobs.erase(key)

func pin_target(key: String) -> void:
	pinned = key
	request(key,true)
	if queue.has(key):
		queue.erase(key)
		queue.push_front(key)

func _process(delta: float) -> void:
	clock += delta
	for key in jobs.keys():
		var job: Dictionary = jobs[key]
		if job.has("http"): continue
		var status := ResourceLoader.load_threaded_get_status(job.path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var texture := ResourceLoader.load_threaded_get(job.path) as Texture2D
			jobs.erase(key)
			if desired.has(key) and texture != null:
				store_texture(key,texture)
			# Only publish one completed native texture per frame as well.
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			jobs.erase(key)
			failures[key] = clock
	if not decode_queue.is_empty():
		var item: Dictionary = decode_queue.pop_front()
		if desired.has(item.key):
			var started := Time.get_ticks_usec()
			var image := Image.new()
			if image.load_jpg_from_buffer(item.bytes) == OK:
				image.generate_mipmaps()
				store_texture(item.key,ImageTexture.create_from_image(image))
			else:
				failures[item.key] = clock
			max_decode_ms = maxf(max_decode_ms,(Time.get_ticks_usec()-started)/1000.0)
	# The queue is small and stale requests are dropped before starting them.
	while jobs.size() < MAX_REQUESTS and not queue.is_empty():
		var key: String = queue.pop_front()
		if not desired.has(key) or is_ready(key): continue
		_start(key)
	peak_jobs = maxi(peak_jobs,jobs.size())

func _start(key: String) -> void:
	if OS.has_feature("web"):
		var http := HTTPRequest.new()
		http.timeout = 20
		http.body_size_limit = 8 * 1024 * 1024
		add_child(http)
		jobs[key] = {"http":http}
		http.request_completed.connect(_downloaded.bind(key,http))
		var base: String = JavaScriptBridge.eval("new URL('.', document.baseURI).href")
		var name: String = REGIONS.ASSETS[key].get_file().get_basename()+".jpg"
		network_requests += 1
		if http.request(base+REGIONS.ASSETS[key].get_base_dir().get_file()+"_chunks/"+name) != OK:
			jobs.erase(key)
			http.queue_free()
			failures[key] = clock
	else:
		var path: String = REGIONS.ASSETS[key]
		if ResourceLoader.load_threaded_request(path,"Texture2D",false) == OK:
			jobs[key] = {"path":path}
		else:
			failures[key] = clock

func _downloaded(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, key: String, http: HTTPRequest) -> void:
	jobs.erase(key)
	http.queue_free()
	if not desired.has(key): return
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		decode_queue.append({"key":key,"bytes":body})
	else:
		failures[key] = clock

func store_texture(key: String, texture: Texture2D) -> void:
	while textures.size() >= MAX_TEXTURES and not textures.has(key):
		var oldest := ""
		for candidate in textures:
			if candidate == active_key or candidate == pinned: continue
			if oldest.is_empty() or used_at[candidate] < used_at[oldest]: oldest = candidate
		if oldest.is_empty(): break
		textures.erase(oldest)
		used_at.erase(oldest)
		evictions += 1
	textures[key] = texture
	used_at[key] = clock
	failures.erase(key)
	texture_loads += 1
	peak_textures = maxi(peak_textures,textures.size())

func show_area(region: int, cave: bool) -> void:
	var started := Time.get_ticks_usec()
	if is_instance_valid(scenery):
		remove_child(scenery)
		scenery.free()
		scenery = null
	var key: String = REGIONS.key(region,cave)
	active_key = key if REGIONS.ASSETS.has(key) else ""
	pinned = ""
	if active_key.is_empty(): return
	assert(textures.has(key),"Cannot enter scenery before it is ready")
	used_at[key] = clock
	scenery = Node2D.new()
	scenery.name = "ActivePlanetScenery"
	scenery.y_sort_enabled = true
	add_child(scenery)
	var ground := Sprite2D.new()
	ground.texture = textures[key]
	ground.centered = false
	ground.scale = REGIONS.SIZE / ground.texture.get_size()
	ground.z_index = -2
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	scenery.add_child(ground)
	AMBIENT_LIFE.add_to(scenery,REGIONS.world if REGIONS is OUTER_REGIONS else 0,region,cave,REGIONS,get_parent())
	if not REGIONS is OUTER_REGIONS:
		EARTH_WATER.add_to(scenery,key,textures[key])
	if REGIONS is OUTER_REGIONS:
		var atmosphere := AMBIENCE.new()
		atmosphere.world = REGIONS.world
		atmosphere.pools = REGIONS.lava_pools(region,cave)
		atmosphere.z_index = 2
		scenery.add_child(atmosphere)
		if not atmosphere.pools.is_empty():
			var mask := Image.create(64,44,false,Image.FORMAT_R8)
			for y in 44:
				for x in 64:
					var point: Vector2 = Vector2((x+0.5)/64.0,(y+0.5)/44.0)*REGIONS.ART_SIZE
					var molten := false
					for pool in atmosphere.pools:
						if ((point-Vector2(pool.x,pool.y))/Vector2(pool.z,pool.w)).length_squared() < 0.96: molten = true
					mask.set_pixel(x,y,Color.WHITE if molten else Color.BLACK)
			var flow := ShaderMaterial.new()
			flow.shader = LAVA_FLOW
			flow.set_shader_parameter("lava_mask",ImageTexture.create_from_image(mask))
			ground.material = flow
	if not cave:
		var index := 0
		for placement in REGIONS.TREES[region]:
			var tree := TREE.instantiate()
			tree.position = REGIONS.from_art(Vector2(placement.x,placement.y))
			tree.scale = Vector2.ONE * 0.31
			tree.tree_style = int(placement.z)
			tree.wind_strength = 3.0
			tree.wind_phase = index * 2.1
			scenery.add_child(tree)
			var plant := PLANT.instantiate()
			plant.position = tree.position+Vector2(90,45)
			plant.scale = Vector2.ONE * 0.13
			plant.plant_style = (index+region) % 3
			plant.wind_strength = 6
			scenery.add_child(plant)
			index += 1
	max_install_ms = maxf(max_install_ms,(Time.get_ticks_usec()-started)/1000.0)

func deactivate() -> void:
	if is_instance_valid(scenery):
		scenery.queue_free()
		scenery = null
	active_key = ""
	pinned = ""
	desired.clear()
	queue.clear()
	decode_queue.clear()
	textures.clear()
	used_at.clear()
	for key in jobs.keys():
		if jobs[key].has("http"):
			jobs[key].http.cancel_request()
			jobs[key].http.queue_free()
			jobs.erase(key)

func _exit_tree() -> void:
	# Drain the two bounded native requests on shutdown, including a request
	# still finishing, so ResourceLoader does not retain its task/refcount.
	for job in jobs.values():
		if job.has("path"):
			var status := ResourceLoader.load_threaded_get_status(job.path)
			if status == ResourceLoader.THREAD_LOAD_LOADED or status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				ResourceLoader.load_threaded_get(job.path)
