extends Node2D

var particles: Array = []
var particle_scene = preload("res://scenes/particle.tscn")
var connection_lines: Line2D

# Fallback spawn positions if no SpawnPoint nodes are found
const DEFAULT_SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(100, 200),
	Vector2(100, 300),
	Vector2(100, 400)
]

func _ready():
	create_connection_lines()
	spawn_initial_particles()

func _process(delta):
	# Update lines every frame to ensure they're visible
	update_connection_lines()

func create_connection_lines():
	connection_lines = Line2D.new()
	connection_lines.width = 2.0
	connection_lines.default_color = Color(0.3, 0.6, 1.0, 0.4)  # Softer blue, subtle
	connection_lines.antialiased = true
	connection_lines.z_index = 5  # Draw on top but not extreme
	add_child(connection_lines)

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
			var collider = collision.get_collider()
			
			# Check if we collided with another particle
			if collider is CharacterBody2D and collider != p:
				# Bounce off other particle
				var bounce_dir = (p.position - collider.position).normalized()
				p.velocity = bounce_dir * speed * 0.5
				p.move_and_collide(p.velocity)
			else:
				# Slide along walls
				var slide = collision.get_remainder().slide(collision.get_normal())
				p.move_and_collide(slide)
		
		# Wrap around screen edges
		if p.position.x < 0:
			p.position.x = 800
		elif p.position.x > 800:
			p.position.x = 0
		
		if p.position.y < 0:
			p.position.y = 600
		elif p.position.y > 600:
			p.position.y = 0
	
	# Update connection lines between particles
	update_connection_lines()

func update_connection_lines():
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
			var p1 = valid_particles[i]
			var p2 = valid_particles[j]
			points.append(p1.position)
			points.append(p2.position)
	
	connection_lines.points = points
