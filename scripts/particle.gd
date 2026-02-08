extends CharacterBody2D

@onready var glow_light = $GlowLight
@onready var trail_particles = $TrailParticles
@onready var survivor_aura = $SurvivorAura

var is_survived: bool = false
var fade_alpha: float = 1.0
var base_color: Color = Color(0.39, 0.59, 1.0)
var survived_color: Color = Color(1.0, 0.84, 0.0)

const RADIUS: float = 8.0

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
	draw_circle(Vector2.ZERO, RADIUS, color)
	
	# Inner highlight
	var highlight_color = Color.WHITE
	highlight_color.a = fade_alpha
	draw_circle(Vector2.ZERO * 0.6, RADIUS * 0.6, highlight_color)
	
	# Survivor ring
	if is_survived:
		var ring_color = survived_color
		ring_color.a = fade_alpha
		draw_arc(Vector2.ZERO, RADIUS + 3, 0, TAU, 16, ring_color, 2.0)

func set_fade(value: float):
	fade_alpha = value
	update_visuals()
	queue_redraw()

func _process(delta):
	# Update trail emission based on movement
	if trail_particles:
		if velocity.length() > 20:
			trail_particles.amount_ratio = 0.8
		else:
			trail_particles.amount_ratio = 0.2
