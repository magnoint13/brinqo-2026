extends Node2D

var particles: Array = []
var particle_scene = preload("res://scenes/particle.tscn")

# Fallback spawn positions if no SpawnPoint nodes are found
const DEFAULT_SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(100, 200),
	Vector2(100, 300),
	Vector2(100, 400)
]

func _ready():
	spawn_initial_particles()

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
	for p in particles:
		if not p.is_survived:
			p.queue_free()
	
	# Rebuild array with only survived particle
	var new_particles = []
	for p in particles:
		if p.is_survived:
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

func apply_movement(direction: Vector2, speed: float, _walls: Node2D):
	for p in particles:
		# Set velocity for this frame
		p.velocity = direction * speed
		
		# Use Godot's built-in collision detection
		var collision = p.move_and_collide(p.velocity)
		
		# Handle collision response
		if collision:
			# Slide along the wall
			var slide = collision.get_remainder().slide(collision.get_normal())
			p.move_and_collide(slide)
		
		# Keep in bounds
		p.position.x = clamp(p.position.x, 8, 792)
		p.position.y = clamp(p.position.y, 8, 592)
