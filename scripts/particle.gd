extends CharacterBody2D

@export var WAVE_STD: float = 40
@export var WAVE_DIRECTION_FACTOR: float = 50.0
@export var WAVE_SIZE: float = 200
@export var BALL_RADIUS: float = 8.0
@export var BALL_SPEED: float = 300.0
@export var MAX_REROLL_ATTEMPS: int = 50
@export var BASE_COLOR: Color = Color(0.39, 0.59, 1.0)
@export var SURVIVED_COLOR: Color = Color(1.0, 0.84, 0.0)

const WAVE_SHADER = preload("res://scripts/wave_shader.gdshader")

@onready var glow_light = $GlowLight
@onready var trail_particles = $TrailParticles
@onready var survivor_aura = $SurvivorAura
@onready var collapsed_timer = $CollapsedTimer
@onready var collapse_particles = $CollapseParticleEffect
 
# State 
var rng: RandomNumberGenerator
var collapsed_state: bool = false
var is_survived: bool = false

# Visual state
var wave_rect: MeshInstance2D
var fade_alpha: float = 1.0
var ring_alpha: float = 0.0  # For animating the survivor ring

#### CORE FUNCTIONALITY ########################################################

func setup(is_new: bool = true):
	collapsed_state = false
	is_survived = not is_new
	fade_alpha = 0.0 if is_new else 1.0
	velocity = Vector2.ZERO

func _ready():
	rng = RandomNumberGenerator.new()
	collapsed_state = false

	wave_rect = MeshInstance2D.new()
	# Setup shape
	var quad = QuadMesh.new()
	quad.size = Vector2(WAVE_SIZE, WAVE_SIZE)
	wave_rect.mesh = quad
	# Setup shader
	var mat = ShaderMaterial.new()
	mat.shader = WAVE_SHADER
	wave_rect.material = mat
	wave_rect.material.set_shader_parameter("time_offset", rng.randf_range(0, 5))
	add_child(wave_rect)

	move_and_slide()
	if trail_particles:
		trail_particles.emitting = true

func _physics_process(delta):
	# Draw every frame
	queue_redraw()
	wave_rect.mesh.size = Vector2(WAVE_SIZE, WAVE_SIZE)

	#### Handle input ####
	var direction = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		direction.x = -1
	if Input.is_action_pressed("move_right"):
		direction.x = 1
	if Input.is_action_pressed("move_up"):
		direction.y = -1
	if Input.is_action_pressed("move_down"):
		direction.y = 1
		
	if Input.is_action_just_pressed("collapse"):
		if not collapsed_state:
			global_position = generate_random_pos(direction)
			collapsed_timer.start()
			to_particle_animated()
		else:
			to_wave_animated()
	
	#### Apply movement ####
	# NOTE: collapsed particles cannot move
	# The position is known, but the velocity is not
	if collapsed_state or direction == Vector2.ZERO:
		return
		
	direction = direction.normalized()

	# Set velocity for this frame
	velocity = direction * BALL_SPEED * delta
	
	# Use Godot's built-in collision detection
	var collision = move_and_collide(velocity)
	
	#### Handle collision response ####
	if collision:
		var collider = collision.get_collider()
		
		# Check if we collided with another particle
		if collider is CharacterBody2D and collider != self:
			# Bounce off other particle
			var bounce_dir = (position - collider.position).normalized()
			velocity = bounce_dir * BALL_SPEED * delta * 0.5
			move_and_collide(velocity)
		else:
			# Slide along walls
			var slide = collision.get_remainder().slide(collision.get_normal())
			move_and_collide(slide)
	
	#### Wrap around screen edges ####
	var window = get_viewport_rect().size
	if position.x < 0:
		position.x += window.x
	elif position.x > window.x:
		position.x -= window.x
	
	if position.y < 0:
		position.y += window.y
	elif position.y > window.y:
		position.y -= window.y

func _draw():
	if collapsed_state:
		#### Draw as particle ####
		wave_rect.visible = false
		glow_light.visible = true
		trail_particles.visible = true
		
		# Main body
		var color = SURVIVED_COLOR if is_survived else BASE_COLOR
		color.a = fade_alpha
		draw_circle(Vector2.ZERO, BALL_RADIUS, color)
		
		# Inner highlight
		draw_circle(
			Vector2.ZERO,
			BALL_RADIUS * 0.6,
			Color(1, 1, 1, fade_alpha)
		)
		
		# Survivor ring (animated via ring_alpha)
		if ring_alpha > 0.01:
			var ring_color = SURVIVED_COLOR
			ring_color.a = ring_alpha * fade_alpha
			draw_arc(Vector2.ZERO, BALL_RADIUS + 3, 0, TAU, 16, ring_color, 2.0)
		
		#### Other effects ####
		# Update trail emission based on movement
		if velocity.length() > 20:
			trail_particles.amount_ratio = 0.8
		else:
			trail_particles.amount_ratio = 0.2
		
		survivor_aura.visible = is_survived and fade_alpha > 0.1
		if is_survived:
			survivor_aura.energy = 1.2 * fade_alpha
			glow_light.color = SURVIVED_COLOR
		else:
			glow_light.color = BASE_COLOR
			
		# Scale light energy by fade_alpha so invisible particles have no glow
		glow_light.energy = 0.8 * fade_alpha

	else:
		#### Draw as wave ####
		wave_rect.visible = true
		glow_light.visible = false
		trail_particles.visible = false

#### VFX ######################################################################

func set_fade(value: float):
	fade_alpha = value

func set_survived(value: bool):
	is_survived = value
	fade_alpha = 1.0
	collapsed_state = false
	
	# Survivor effect
	if is_survived and survivor_aura:
		var tween = create_tween().set_loops(3)
		tween.tween_property(survivor_aura, "energy", 1.8, 0.3)
		tween.tween_property(survivor_aura, "energy", 1.2, 0.3)

func _on_collapsed_timer_timeout():
	to_wave_animated()

func to_particle_animated():
	if not collapsed_state:
		collapse_particles.process_material.radial_velocity *= -1
		collapse_particles.restart()
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.2)
		tween.tween_callback(func():
			collapsed_state = true
			scale = Vector2(1, 1)
		)

func to_wave_animated():
	if collapsed_state:
		collapse_particles.restart()
		collapsed_state = false
		scale = Vector2(0.2, 0.2)
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", Vector2(1, 1), 0.2)
		
func generate_random_pos(direction: Vector2) -> Vector2:
	# The generated random number may end up inside a wall
	# In that case, regenerate
	var attempts = 0
	
	# Requiredfor the collision testing
	var space_state = get_world_2d().direct_space_state
	
	while attempts < MAX_REROLL_ATTEMPS:
		# Here, we make easier the tunnel effect by giving more priority to the
		# direction the player is moving to
		var target_pos = Vector2(
			rng.randfn(global_position.x + WAVE_DIRECTION_FACTOR * direction.x, WAVE_STD),
			rng.randfn(global_position.y + WAVE_DIRECTION_FACTOR * direction.y, WAVE_STD)
		)

		# We cannot use regular collision detection methods here, as they check
		# objects in the middle of the trayectory. But in this case, that is exactly
		# what we don't want.
		var query = PhysicsPointQueryParameters2D.new()
		query.position = target_pos
		query.collision_mask = collision_mask # Same mask as this object

		# Query returns the intersecting objects
		var result = space_state.intersect_point(query)
		if result.is_empty():
			return target_pos
		attempts += 1
		
	# Else, fallback to center (keep the current position)
	return global_position
