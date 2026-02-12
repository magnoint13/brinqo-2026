extends Node2D

var particles: Array = []
var particle_scene = preload("res://scenes/particle.tscn")
var connection_lines: Line2D

var spawn_positions : Array[Vector2] = []
var last_movement_direction: Vector2 = Vector2.ZERO
#@onready var spawnPointContainer : Array[SpawnPoint] = get_parent().get_node("SpawnPoints").get_children() as Array[SpawnPoint] 
# Fallback spawn positions if no SpawnPoint nodes are found
const DEFAULT_SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(100, 200),
	Vector2(100, 300),
	Vector2(100, 400)
]

func _ready():
	var spawnPointContainer = get_parent().get_node("SpawnPoints").get_children() as Array[SpawnPoint] 
	
	for spawnPoint in spawnPointContainer:
		if spawnPoint.enabled:
			spawn_positions.append(spawnPoint.position)
	
	if spawn_positions.is_empty():
		print("ERROR: Missing spawnpoints")
		
	create_connection_lines()
	spawn_initial_particles()

func _process(_delta):
	update_connection_lines()

func create_connection_lines():
	connection_lines = Line2D.new()
	connection_lines.width = 2.0
	connection_lines.default_color = Color(0.3, 0.6, 1.0, 0.4)
	connection_lines.antialiased = true
	add_child(connection_lines)
	
func update_connection_lines():
	if connection_lines == null:
		return
	
	# Get valid particles with good visibility
	var valid_particles = []
	for p in particles:
		if is_instance_valid(p) and p.fade_alpha > 0.1:
			valid_particles.append(p)
	
	if valid_particles.size() < 2:
		connection_lines.points = []
		return
	
	# Build connection lines
	var points = []
	for i in range(valid_particles.size()):
		for j in range(i + 1, valid_particles.size()):
			points.append(valid_particles[i].position)
			points.append(valid_particles[j].position)
	
	connection_lines.points = points

func fade_out_lines(duration: float = 0.2):
	if connection_lines:
		var tween = create_tween()
		tween.tween_method(_set_lines_alpha, 0.4, 0.0, duration)

func fade_in_lines(duration: float = 0.5):
	if connection_lines:
		var tween = create_tween()
		tween.tween_method(_set_lines_alpha, 0.0, 0.4, duration)

func _set_lines_alpha(alpha: float):
	if connection_lines:
		var color = connection_lines.default_color
		color.a = alpha
		connection_lines.default_color = color

func spawn_initial_particles():
	for i in range(spawn_positions.size()):
		var p = particle_scene.instantiate()
		p.spawn_index = i  # Store which spawnpoint this particle came from
		p.position = spawn_positions[i]
		p.setup(true)  # Starts invisible
		add_child(p)
		particles.append(p)
		
		# Fade in
		var tween = create_tween()
		tween.tween_method(p.set_fade, 0.0, 1.0, 0.5)

func respawn_after_collapse(survivor: Node2D):
	# Remove all particles except the survivor from the array
	var new_particles = []
	for p in particles:
		if p == survivor and is_instance_valid(p):
			new_particles.append(p)
		else:
			# Already fading out and will be freed by tween callback
			pass
	particles = new_particles
	
	# Get all spawn positions
	#var spawn_positions = get_spawn_positions()
	
	# Get the spawn index of the survivor (ID-based association)
	var occupied_spawn_index = survivor.spawn_index
	
	# Create list of available spawn indices (excluding the survivor's spawn)
	var available_indices = []
	for i in range(spawn_positions.size()):
		if i != occupied_spawn_index:
			available_indices.append(i)
	
	# Shuffle available indices
	available_indices.shuffle()
	
	# Spawn new particles to fill all available spawnpoints (excluding survivor's)
	var target_particle_count = spawn_positions.size() - 1
	var spawned_count = 0
	for i in range(min(target_particle_count, available_indices.size())):
		var spawn_index = available_indices[i]
		var spawn_pos = spawn_positions[spawn_index]
		var p = particle_scene.instantiate()
		p.spawn_index = spawn_index  # Store spawn index for this new particle
		p.global_position = spawn_pos
		p.setup(true)  # Starts invisible
		add_child(p)
		particles.append(p)
		spawned_count += 1
		
		# Fade in
		var tween = create_tween()
		tween.tween_method(p.set_fade, 0.0, 1.0, 0.5)
	
	# Safety: if we couldn't spawn enough, spawn at any available position
	while spawned_count < target_particle_count and spawn_positions.size() > spawned_count:
		var spawn_idx = spawned_count % spawn_positions.size()
		var spawn_pos = spawn_positions[spawn_idx]
		# Skip if this is the occupied spawn
		if spawn_idx == occupied_spawn_index:
			spawned_count += 1
			continue
			
		var p = particle_scene.instantiate()
		p.spawn_index = spawn_idx  # Store spawn index
		p.global_position = spawn_pos
		p.setup(true)
		add_child(p)
		particles.append(p)
		spawned_count += 1
		
		var tween = create_tween()
		tween.tween_method(p.set_fade, 0.0, 1.0, 0.5)
		
	# Ensure everyone is in wave form
	for p in particles:
		p.to_wave_animated()

func reset():
	for p in particles:
		if is_instance_valid(p):
			p.queue_free()
	particles.clear()
	spawn_initial_particles()

func apply_movement(direction: Vector2, speed: float):
	# Store last movement direction for collapse mechanic
	if direction != Vector2.ZERO:
		last_movement_direction = direction
	
	for p in particles:
		if not is_instance_valid(p) or p.collapsed_state:
			continue
		
		p.velocity = direction * speed
		var collision = p.move_and_collide(p.velocity)
		
		if collision:
			var collider = collision.get_collider()
			
			if collider is CharacterBody2D and collider != p:
				var bounce_dir = (p.position - collider.position).normalized()
				p.velocity = bounce_dir * speed * 0.5
				p.move_and_collide(p.velocity)
			else:
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
			
			
func collapse_all():
	var ref_index = randi_range(0, particles.size() - 1)
	var ref = particles[ref_index]
	var new_pos = ref.generate_random_pos(last_movement_direction)
	var move_vector = ref.global_position - new_pos
	ref.global_position = new_pos
	ref.to_particle_animated()
	
	for i in range(particles.size()):
		if i == ref_index: continue
		particles[i].global_position += move_vector
		particles[i].to_particle_animated()

func _valid_particles():
	# Get valid particles
	var valid_particles = []
	for p in particles:
		if p.collapsed_state:
			return null
		if is_instance_valid(p) and p.fade_alpha > 0.1:
			valid_particles.append(p)
	
	return valid_particles

func _find_particles_center(valid_particles: Array) -> Vector2:
	# Calculate rotation center
	var center: Vector2
	if valid_particles.size() == 1:
		return valid_particles[0].position
		
	if valid_particles.size() == 2:
		var v = (valid_particles[0].position - valid_particles[1].position) / 2
		center = valid_particles[1].position + v
		
	if valid_particles.size() == 3:
		# Check if particles form a line (colinear)
		var p0 = valid_particles[0].position
		var p1 = valid_particles[1].position
		var p2 = valid_particles[2].position
		
		# Calculate vectors
		var v1 = p1 - p0
		var v2 = p2 - p0
		
		# Check if colinear using cross product (2D equivalent)
		var cross = v1.x * v2.y - v1.y * v2.x
		var is_colinear = abs(cross) < 0.01
		
		if is_colinear:
			# Particles are in a line - find spatial middle particle
			# Sort by position along the line
			valid_particles.sort_custom(func(a, b): return a.position.x < b.position.x if abs(v1.x) > abs(v1.y) else a.position.y < b.position.y)
			center = valid_particles[1].position  # Middle particle
		else:
			# Triangle - use centroid
			center = (p0 + p1 + p2) / 3.0
	else:
		# For 2+ particles (not 3), use centroid
		center = Vector2.ZERO
		for p in valid_particles:
			center += p.position
		center /= valid_particles.size()

	return center

func rotate_particles(delta: float, direction: int, rotation_speed: float):
	var valid_particles = _valid_particles()
	if not valid_particles or valid_particles.size() == 1:
		return
	var center = _find_particles_center(valid_particles)
	
	# Apply rotation
	var rotation_angle = deg_to_rad(rotation_speed * delta * direction)
	
	for p in valid_particles:
		# Calculate offset from center
		var offset = p.position - center
		
		# Rotate the offset
		var rotated_offset = offset.rotated(rotation_angle)
		
		# Calculate new position
		var new_position = center + rotated_offset
		
		# Calculate movement needed
		var movement = new_position - p.position
		
		# Apply movement with collision
		p.velocity = movement / delta
		p.move_and_collide(movement)
			
func scale_particles(delta: float, scale_dir: int, scale_speed: float):
	var valid_particles = _valid_particles()
	if not valid_particles or valid_particles.size() == 1:
		return
	var center = _find_particles_center(valid_particles)
	
	for p in valid_particles:
		var move_vector = p.position - center
		var movement = move_vector.normalized() * scale_speed * scale_dir
		p.velocity = movement / delta
		p.move_and_collide(movement)
