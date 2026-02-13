extends Node2D

var particles: Array = []
var level_main: Node2D = null
var particle_scene = preload("res://scenes/particle.tscn")
var connection_lines: Line2D
var collapseSoundStream = preload("res://resources/sfx/collapse.wav")
var collapseAudioStream : AudioStreamPlayer
var reentangleSoundStream = preload("res://resources/sfx/sfx_reentanglement.wav")
var reentangleAudioStream : AudioStreamPlayer


var spawn_positions: Array[Vector2] = []
var spawn_is_entangled: Array[bool] = []
var last_movement_direction: Vector2 = Vector2.ZERO
# Fallback spawn positions if no SpawnPoint nodes are found
const DEFAULT_SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(100, 200),
	Vector2(100, 300),
	Vector2(100, 400)
]
const RIPPLE_SCENE = preload("res://scripts/RippleEffect.gd")

func _ready():
	var spawnPointContainer = get_parent().get_node("SpawnPoints").get_children() as Array[SpawnPoint] 
	for spawnPoint in spawnPointContainer:
		if spawnPoint.enabled:
			spawn_positions.append(spawnPoint.position)
			spawn_is_entangled.append(spawnPoint.entangled)
	
	if spawn_positions.is_empty():
		print("ERROR: Missing spawnpoints")
		
	create_connection_lines()
	spawn_initial_particles()
	
	## ADD WALLS AROUND VIEWPORT
	_add_viewport_boundary_walls()
	
	collapseAudioStream = AudioStreamPlayer.new()	
	collapseAudioStream.stream = collapseSoundStream
	collapseAudioStream.volume_db = -7
	add_child(collapseAudioStream)
	
	reentangleAudioStream = AudioStreamPlayer.new()
	reentangleAudioStream.stream = reentangleSoundStream
	reentangleAudioStream.volume_db = -7
	add_child(reentangleAudioStream)

func _process(_delta):
	update_connection_lines()

func create_connection_lines():
	connection_lines = Line2D.new()
	connection_lines.width = 5.0
	connection_lines.default_color = Color(0.3, 0.6, 1.0, 0.4)
	connection_lines.antialiased = true
	add_child(connection_lines)
	
func update_connection_lines():
	if connection_lines == null:
		return
	
	connection_lines.visible = true
	
	# Get valid particles with good visibility
	var valid_particles = []
	for p in particles:
		if is_instance_valid(p) and p.fade_alpha > 0.1 and p.is_entangled:
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
		add_child(p)
		particles.append(p)
		p.spawn_index = i  # Store which spawnpoint this particle came from
		p.position = spawn_positions[i]
		p.setup(true, spawn_is_entangled[i])  # Starts invisible
		p.is_entangled = spawn_is_entangled[i]
		
		# Fade in
		var tween = create_tween()
		tween.tween_method(p.set_fade, 0.0, 1.0, 0.5)

func reset():
	for p in particles:
		if is_instance_valid(p):
			p.queue_free()
	particles.clear()
	spawn_initial_particles()

#### COLLAPSE LOGIC ############################################################

func break_entanglement():
	# Select new player
	var new_player_index = randi_range(0, particles.size() - 1)
	
	for i in range(particles.size()):
		if i == new_player_index:
			# Ensure survivor is in wave state so they can be controlled immediately
			particles[i].to_wave_animated()
			particles[i].is_entangled = true
		else:
			particles[i].is_entangled = false


func collapse_all():
	# ensure all are entangled and in wave form
	var valid_particles = _valid_particles()
	
	for p in valid_particles:
		p.global_position = p.generate_random_pos(last_movement_direction)
		p.to_particle_animated()
	
	collapseAudioStream.play()
	
func entanglement_animation(entangle_position: Vector2):
	# Animation
	var ripple_efect = RIPPLE_SCENE.new()
	ripple_efect.position = entangle_position
	ripple_efect.z_index = 5
	ripple_efect.ring_color = Color(1, 1, 0, 0.4)
	add_child(ripple_efect)
	level_main.screen_shake(5.0, 1.0)

	for p in particles:
		if p.is_entangled:
			var mat = p.wave_rect.material as ShaderMaterial
			if not mat: continue
			
			var tween = create_tween()
			tween.tween_property(mat, "shader_parameter/color_tint", Color(2.5, 2.5, 0.5), 0.1)
			
			for i in range(3):
				tween.tween_property(mat, "shader_parameter/color_tint", Color(0.5, 0.0, 0.5), 0.05)
				tween.tween_property(mat, "shader_parameter/color_tint", Color(2.5, 0.2, 2.5), 0.05)
			tween.tween_property(mat, "shader_parameter/color_tint", Color(0.0, 0.8, 1.5), 0.3)
			tween.tween_property(mat, "shader_parameter/color_tint", Color(1.0, 1.0, 1.0), 1.0)
	
	reentangleAudioStream.play()

#### MOVEMENT LOGIC ############################################################

func apply_movement(direction: Vector2, speed: float):
	# Store last movement direction for collapse mechanic
	if direction != Vector2.ZERO:
		last_movement_direction = direction
	
	for p in particles:
		if not is_instance_valid(p) or p.collapsed_state or not p.is_entangled:
			continue
		
		p.velocity = direction * speed
		var collision = p.move_and_collide(p.velocity)
		
		if collision:
			var collider = collision.get_collider()
			
			if collider is CharacterBody2D and collider != p:
				# If colliding with other untangled particle, create system
				if collider is Particle and \
						(p.is_entangled and not p.collapsed_state) and \
						(not collider.is_entangled and not collider.collapsed_state):
					# update state
					collider.is_entangled = true
					# play animation+sounds
					entanglement_animation(p.position)
					# notify to level to update UI
					if level_main:
						level_main.reentangle()
					
				# handle collision
				var bounce_dir = (p.position - collider.position).normalized()
				p.velocity = bounce_dir * speed * 0.5
				p.move_and_collide(p.velocity)
			else:
				var slide = collision.get_remainder().slide(collision.get_normal())
				p.move_and_collide(slide)

func _valid_particles():
	# Get valid particles
	var valid_particles = []
	for p in particles:
		if p.collapsed_state:
			return null
		if is_instance_valid(p) and p.fade_alpha > 0.1 and p.is_entangled:
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
	#var rotation_angle = deg_to_rad(rotation_speed * delta * direction)
	
	for p in valid_particles:
		# Calculate offset from center
		var offset = p.position - center
		var radius = offset.length()
		if radius < 1: # avoid problems when the particle is at the center
			continue
			
		var angular_vel = rotation_speed / radius
		var rotation_angle = angular_vel * delta * direction
		
		# Rotate the offsetz
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
		var movement = move_vector.normalized() * scale_speed * scale_dir * delta
		p.velocity = movement / delta
		p.move_and_collide(movement)

## ADD WALLS AROUND VIEWPORT
## Creates invisible StaticBody2D walls at viewport boundaries
## Walls are positioned slightly outside (10px) so particles collide exactly at viewport edge
func _add_viewport_boundary_walls():
	var viewport_size = Vector2(800, 600)
	var wall_thickness = 200.0  # Thick enough to prevent tunneling
	
	# Left wall - positioned so inner edge is at x=0
	_create_invisible_wall("LeftWall", Vector2(-wall_thickness / 2, viewport_size.y / 2), Vector2(wall_thickness, viewport_size.y + wall_thickness * 2))
	
	# Right wall - positioned so inner edge is at x=800
	_create_invisible_wall("RightWall", Vector2(viewport_size.x + wall_thickness / 2, viewport_size.y / 2), Vector2(wall_thickness, viewport_size.y + wall_thickness * 2))
	
	# Top wall - positioned so inner edge is at y=0
	_create_invisible_wall("TopWall", Vector2(viewport_size.x / 2, -wall_thickness / 2), Vector2(viewport_size.x + wall_thickness * 2, wall_thickness))
	
	# Bottom wall - positioned so inner edge is at y=600
	_create_invisible_wall("BottomWall", Vector2(viewport_size.x / 2, viewport_size.y + wall_thickness / 2), Vector2(viewport_size.x + wall_thickness * 2, wall_thickness))

## Creates an invisible StaticBody2D wall with collision
func _create_invisible_wall(wall_name: String, place_position: Vector2, size: Vector2):
	var wall = StaticBody2D.new()
	wall.name = wall_name
	wall.collision_layer = 1  # Particles collide with layer 1
	wall.collision_mask = 0   # Walls don't detect collisions themselves
	
	var collision_shape = CollisionShape2D.new()
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.size = size
	collision_shape.shape = rectangle_shape
	
	wall.add_child(collision_shape)
	wall.position = place_position
	add_child(wall)
