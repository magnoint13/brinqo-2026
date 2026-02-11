extends CharacterBody2D

@onready var glow_light = $GlowLight
@onready var trail_particles = $TrailParticles
@onready var collision_shape = $CollisionShape2D

var is_survived: bool = false
var fade_alpha: float = 1.0
var base_color: Color = Color(0.39, 0.59, 1.0)
var spawn_index: int = -1  # Index of the spawnpoint this particle originated from

const RADIUS: float = 8.0

# Wave state variables
const WAVE_SHADER = preload("res://resources/wave_shader.gdshader")
@export var WAVE_STD: float = 25
@export var WAVE_DIRECTION_FACTOR: float = 50.0
@export var WAVE_SIZE: float = 200
var collapsed_state: bool = false
var wave_rect: MeshInstance2D
var rng: RandomNumberGenerator

func setup(is_new: bool = true):
	is_survived = not is_new
	fade_alpha = 0.0 if is_new else 1.0
	collapsed_state = false
	velocity = Vector2.ZERO
	update_visuals()
	queue_redraw()

func _ready():
	rng = RandomNumberGenerator.new()
	
	# Setup wave shader mesh
	wave_rect = MeshInstance2D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(WAVE_SIZE, WAVE_SIZE)
	wave_rect.mesh = quad
	var mat = ShaderMaterial.new()
	mat.shader = WAVE_SHADER
	wave_rect.material = mat
	wave_rect.material.set_shader_parameter("time_offset", rng.randf_range(0, 5))
	add_child(wave_rect)
	
	move_and_slide()
	if trail_particles:
		trail_particles.emitting = true
	queue_redraw()

func set_survived(value: bool):
	is_survived = value
	fade_alpha = 1.0
	update_visuals()
	queue_redraw()

func update_visuals():
	if glow_light:
		glow_light.color = base_color
		# Scale light energy by fade_alpha so invisible particles have no glow
		glow_light.energy = 0.8 * fade_alpha

func _draw():
	if collapsed_state:
		#### Draw as particle ####
		wave_rect.visible = false
		glow_light.visible = true
		trail_particles.visible = true
		
		var color = base_color
		color.a = fade_alpha
		
		# Main body
		draw_circle(Vector2.ZERO, RADIUS, color)
		
		# Inner highlight
		var highlight_color = Color.WHITE
		highlight_color.a = fade_alpha
		draw_circle(Vector2.ZERO * 0.6, RADIUS * 0.6, highlight_color)
	else:
		#### Draw as wave ####
		wave_rect.visible = true
		glow_light.visible = false
		trail_particles.visible = false

func set_fade(value: float):
	fade_alpha = value
	update_visuals()
	queue_redraw()

func _process(_delta):
	# Update trail emission based on movement
	if trail_particles:
		if velocity.length() > 20:
			trail_particles.amount_ratio = 0.8
		else:
			trail_particles.amount_ratio = 0.2
	
	# Keep wave rect updated
	if wave_rect:
		wave_rect.mesh.size = Vector2(WAVE_SIZE, WAVE_SIZE)
		queue_redraw()

#### Wave Collapse Functions ####

func generate_random_pos(direction: Vector2) -> Vector2:
	# Generate random position using Gaussian distribution
	# Favors the direction the particle is moving
	var attempts = 0
	var space_state = get_world_2d().direct_space_state
	
	while attempts < 50:
		attempts += 1
		
		var target_pos = Vector2(
			rng.randfn(global_position.x + WAVE_DIRECTION_FACTOR * direction.x, WAVE_STD),
			rng.randfn(global_position.y + WAVE_DIRECTION_FACTOR * direction.y, WAVE_STD)
		)
		
		if target_pos.distance_to(global_position) > WAVE_SIZE:
			continue
		
		# Check if position is valid (not inside a wall)
		var query = PhysicsShapeQueryParameters2D.new()
		query.shape = collision_shape.shape
		query.transform = Transform2D(0, target_pos)
		query.collision_mask = collision_mask
		
		var result = space_state.intersect_shape(query)
		if result.is_empty():
			return target_pos
	
	# Fallback: return current position
	return global_position

func to_wave_animated():
	# Animate from particle to wave state
	if collapsed_state:
		collapsed_state = false
		scale = Vector2(0.2, 0.2)
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
		queue_redraw()

func to_particle_animated():
	# Animate from wave to particle state
	if not collapsed_state:
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.2)
		tween.tween_callback(func():
			collapsed_state = true
			scale = Vector2(1.0, 1.0)
			queue_redraw()
		)

func _on_collapsed_timer_timeout():
	to_wave_animated()
