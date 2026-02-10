extends Node2D

#### Config ####
@export var CONNECTION_LINE_COLOR: Color = Color(0.3, 0.6, 1.0, 0.4)
@export var CONNECTION_LINE_WIDTH: float = 2.0
# Fallback spawn positions if no SpawnPoint nodes are found
@export var DEFAULT_SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(100, 200),
	Vector2(100, 300),
	Vector2(100, 400)
]

#### State ####
var particle_scene = preload("res://scenes/particle.tscn")
var particles: Array = []
var connection_lines: Line2D

func _ready():
	#### Create connection lines ###
	# Line2D is a poly line, it contains an array of 2D points to render to
	connection_lines = Line2D.new()
	connection_lines.width = CONNECTION_LINE_WIDTH
	connection_lines.default_color = CONNECTION_LINE_COLOR
	connection_lines.antialiased = true
	add_child(connection_lines)
	
	spawn_initial_particles()

func spawn_initial_particles():
	var spawn_positions = get_spawn_positions()
	
	for pos in spawn_positions:
		var p = particle_scene.instantiate()
		p.position = pos
		p.setup(true)  # Starts invisible (alpha = 0)
		add_child(p)
		particles.append(p)
		
		# Fade in initial particles
		var tween = create_tween()
		tween.tween_method(p.set_fade, 0.0, 1.0, 0.5)

func get_spawn_positions() -> Array[Vector2]:
	# Look for SpawnPoint nodes in the parent (level) scene
	var spawn_positions: Array[Vector2] = []
	var parent = get_parent()
	
	if parent:
		for child in parent.get_children():
			if child is SpawnPoint:
				spawn_positions.append(child.global_position)
	
	# Fallback to default if no spawn points found
	if spawn_positions.is_empty():
		spawn_positions = DEFAULT_SPAWN_POSITIONS.duplicate()
	
	return spawn_positions

func _process(_delta):
	### Update lines to match the new particle positions ###
	if connection_lines == null:
		return
	
	# Filter out invalid particles
	var valid_particles = []
	for p in particles:
		if is_instance_valid(p) and p.fade_alpha > 0.1:
			valid_particles.append(p)
	
	if valid_particles.size() < 2:
		connection_lines.points = []
		return
	
	# Build points array
	var points = []
	for i in range(valid_particles.size()):
		for j in range(i + 1, valid_particles.size()):
			points.append(valid_particles[i].position)
			points.append(valid_particles[j].position)
	
	connection_lines.points = points

func respawn_two_particles(_exclude_position: Vector2):
	var available_spawns = get_spawn_positions().duplicate()
	available_spawns.shuffle()
	
	for i in range(2):
		var spawn = available_spawns[i]
		var p = particle_scene.instantiate()
		p.position = spawn
		p.setup(true)  # Starts invisible (alpha = 0)
		add_child(p)
		particles.append(p)
		
		# Create fade-in tween (quick fade in)
		var tween = create_tween()
		tween.tween_method(p.set_fade, 0.0, 1.0, 0.5)

func get_survived_particle() -> Node2D:
	for p in particles:
		if p.is_survived:
			return p
	return null

func clear_non_survived():
	# Remove all non-survived particles from scene
	var new_particles = []
	for p in particles:
		if not p.is_survived:
			p.queue_free()
		else:
			p.collapsed_state = false
			new_particles.append(p)
	particles = new_particles

func add_particle(pos: Vector2, is_survived: bool = false):
	var p = particle_scene.instantiate()
	p.position = pos
	p.setup(false if is_survived else true)
	p.set_survived(is_survived)
	add_child(p)
	particles.append(p)

func reset():
	for p in particles:
		p.queue_free()
	particles.clear()
	spawn_initial_particles()
