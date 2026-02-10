extends CharacterBody2D

@export var BALL_RADIUS: float = 8.0
@export var BALL_SPEED: float = 300.0
@export var BASE_COLOR: Color = Color(0.39, 0.59, 1.0)
@export var SURVIVED_COLOR: Color = Color(1.0, 0.84, 0.0)

@onready var glow_light = $GlowLight
@onready var trail_particles = $TrailParticles
@onready var survivor_aura = $SurvivorAura

# State
var rng: RandomNumberGenerator
var collapsed_state: bool = true
var is_survived: bool = false

# Visual state
var fade_alpha: float = 1.0
var ring_alpha: float = 0.0  # For animating the survivor ring

#### CORE FUNCTIONALITY ########################################################

func setup(is_new: bool = true):
	is_survived = not is_new
	fade_alpha = 0.0 if is_new else 1.0
	velocity = Vector2.ZERO

func _ready():
	rng = RandomNumberGenerator.new()
	move_and_slide()
	if trail_particles:
		trail_particles.emitting = true

func _physics_process(delta):
	# Draw every frame
	queue_redraw()
	
	# Update trail emission based on movement
	if trail_particles:
		if velocity.length() > 20:
			trail_particles.amount_ratio = 0.8
		else:
			trail_particles.amount_ratio = 0.2

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
		collapsed_state = not collapsed_state
	
	#### Apply movement ####
	if direction == Vector2.ZERO:
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
	if position.x < 0:
		position.x = 800
	elif position.x > 800:
		position.x = 0
	
	if position.y < 0:
		position.y = 600
	elif position.y > 600:
		position.y = 0

func _draw():
	if collapsed_state:
		#### Draw as particle ####
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
		pass

#### VFX ######################################################################


func set_fade(value: float):
	fade_alpha = value

func set_survived(value: bool):
	is_survived = value
	fade_alpha = 1.0
	
	# Survivor effect
	if is_survived and survivor_aura:
		var tween = create_tween().set_loops(3)
		tween.tween_property(survivor_aura, "energy", 1.8, 0.3)
		tween.tween_property(survivor_aura, "energy", 1.2, 0.3)
