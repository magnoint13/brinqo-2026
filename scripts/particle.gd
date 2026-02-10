extends CharacterBody2D

@export var BALL_RADIUS: float = 8.0
@export var BALL_SPEED: float = 300.0

@onready var glow_light = $GlowLight
@onready var trail_particles = $TrailParticles
@onready var survivor_aura = $SurvivorAura

var collapsed_state: bool = false

var is_survived: bool = false
var fade_alpha: float = 1.0
var ring_alpha: float = 0.0  # For animating the survivor ring
var base_color: Color = Color(0.39, 0.59, 1.0)
var survived_color: Color = Color(1.0, 0.84, 0.0)

func setup(is_new: bool = true):
	is_survived = not is_new
	fade_alpha = 0.0 if is_new else 1.0
	velocity = Vector2.ZERO
	update_visuals()
	queue_redraw()

func _ready():
	move_and_slide()
	if trail_particles:
		trail_particles.emitting = true

func set_survived(value: bool):
	is_survived = value
	fade_alpha = 1.0
	update_visuals()
	queue_redraw()
	
	if is_survived:
		pulse_survivor_effect()

func update_visuals():
	if survivor_aura:
		survivor_aura.visible = is_survived and fade_alpha > 0.1
		if is_survived:
			survivor_aura.energy = 1.2 * fade_alpha
	
	if glow_light:
		if is_survived:
			glow_light.color = survived_color
		else:
			glow_light.color = base_color
		# Scale light energy by fade_alpha so invisible particles have no glow
		glow_light.energy = 0.8 * fade_alpha

func pulse_survivor_effect():
	if survivor_aura:
		var tween = create_tween().set_loops(3)
		tween.tween_property(survivor_aura, "energy", 1.8, 0.3)
		tween.tween_property(survivor_aura, "energy", 1.2, 0.3)

func _draw():
	var color = survived_color if is_survived else base_color
	color.a = fade_alpha
	
	# Main body
	draw_circle(Vector2.ZERO, BALL_RADIUS, color)
	
	# Inner highlight
	var highlight_color = Color.WHITE
	highlight_color.a = fade_alpha
	draw_circle(Vector2.ZERO * 0.6, BALL_RADIUS * 0.6, highlight_color)
	
	# Survivor ring (animated via ring_alpha)
	if ring_alpha > 0.01:
		var ring_color = survived_color
		ring_color.a = ring_alpha * fade_alpha
		draw_arc(Vector2.ZERO, BALL_RADIUS + 3, 0, TAU, 16, ring_color, 2.0)

func set_fade(value: float):
	fade_alpha = value
	update_visuals()
	queue_redraw()

func _physics_process(delta):
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
	
	if direction == Vector2.ZERO:
		return
		
	#### Apply movement ####
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
	
	# Wrap around screen edges
	if position.x < 0:
		position.x = 800
	elif position.x > 800:
		position.x = 0
	
	if position.y < 0:
		position.y = 600
	elif position.y > 600:
		position.y = 0
