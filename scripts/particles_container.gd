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
	update_connection_lines()

func create_connection_lines():
	connection_lines = Line2D.new()
	connection_lines.width = 2.0
	connection_lines.default_color = Color(0.3, 0.6, 1.0, 0.4)
	connection_lines.antialiased = true
	connection_lines.z_index = 5
	add_child(connection_lines)

func get_spawn_positions() -> Array[Vector2]:
	var spawn_positions: Array[Vector2] = []
	var parent = get_parent()
	
	if parent:
		for child in parent.get_children():
			if child is SpawnPoint:
				spawn_positions.append(child.global_position)
	
	if spawn_positions.is_empty():
		spawn_positions = DEFAULT_SPAWN_POSITIONS.duplicate()
	
	return spawn_positions

func spawn_initial_particles():
	var spawn_positions = get_spawn_positions()
	
	for pos in spawn_positions:
		var p = particle_scene.instantiate()
		p.position = pos
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
	
	# Get survivor's current position
	var survivor_pos = survivor.global_position
	
	# Get all spawn positions
	var spawn_positions = get_spawn_positions()
	
	# Find the closest spawn point to the survivor
	var closest_spawn_index = -1
	var closest_distance = 999999.0
	
	for i in range(spawn_positions.size()):
		var dist = spawn_positions[i].distance_to(survivor_pos)
		if dist < closest_distance:
			closest_distance = dist
			closest_spawn_index = i
	
	# Create list of available spawn indices (excluding the one closest to survivor)
	var available_indices = []
	for i in range(spawn_positions.size()):
		if i != closest_spawn_index:
			available_indices.append(i)
	
	# Shuffle available indices
	available_indices.shuffle()
	
	# Spawn 2 new particles
	var spawned_count = 0
	for i in range(min(2, available_indices.size())):
		var spawn_index = available_indices[i]
		var spawn_pos = spawn_positions[spawn_index]
		var p = particle_scene.instantiate()
		p.global_position = spawn_pos
		p.setup(true)  # Starts invisible
		add_child(p)
		particles.append(p)
		spawned_count += 1
		
		# Fade in
		var tween = create_tween()
		tween.tween_method(p.set_fade, 0.0, 1.0, 0.5)
	
	# Safety: if we couldn't spawn 2, spawn at any available position
	while spawned_count < 2 and spawn_positions.size() > spawned_count:
		var spawn_pos = spawn_positions[spawned_count % spawn_positions.size()]
		# Make sure this position is far enough from survivor
		if spawn_pos.distance_to(survivor_pos) > 50.0:  # At least 50px away
			var p = particle_scene.instantiate()
			p.global_position = spawn_pos
			p.setup(true)
			add_child(p)
			particles.append(p)
			spawned_count += 1
			
			var tween = create_tween()
			tween.tween_method(p.set_fade, 0.0, 1.0, 0.5)
		else:
			# Try offsetting the position
			var offset_pos = spawn_pos + Vector2(50, 0)
			var p = particle_scene.instantiate()
			p.global_position = offset_pos
			p.setup(true)
			add_child(p)
			particles.append(p)
			spawned_count += 1
			
			var tween = create_tween()
			tween.tween_method(p.set_fade, 0.0, 1.0, 0.5)

func reset():
	for p in particles:
		if is_instance_valid(p):
			p.queue_free()
	particles.clear()
	spawn_initial_particles()

func apply_movement(direction: Vector2, speed: float, _walls: Node2D):
	for p in particles:
		if not is_instance_valid(p):
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
