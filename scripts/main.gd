extends Node2D

const BALL_RADIUS = 8.0
const BALL_SPEED = 300.0
const COLLAPSE_MIN_TIME = 7.0
const COLLAPSE_MAX_TIME = 15.0

@onready var particles_node = $Particles
@onready var collapse_timer = $CollapseTimer
@onready var camera = $Camera2D
@onready var walls = $Walls/TileMapLayer
@onready var red_zones = $RedZone/TileMapLayer
@onready var green_zones = $GreenZone/TileMapLayer
@onready var hud = $HUD

# Simple state tracking
var game_over = false
var game_won = false
var is_processing_collapse = false
var current_collapse_max_time: float = 15.0

# Input tracking
var c_key_was_pressed = false

func _ready():
	randomize()
	collapse_timer.timeout.connect(trigger_collapse)
	start_collapse_timer()
	hud.show_progress_bar()

func _process(delta):
	if game_over or game_won:
		return
	
	handle_input(delta)
	update_timer_display()

func handle_input(delta: float):
	# Movement
	var direction = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		direction.x = -1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		direction.x = 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		direction.y = -1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		direction.y = 1
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		particles_node.apply_movement(direction, BALL_SPEED * delta, walls)
	
	# Force collapse on C key
	var c_pressed = Input.is_key_pressed(KEY_C)
	if c_pressed and not c_key_was_pressed and not is_processing_collapse:
		collapse_timer.stop()
		trigger_collapse()
	c_key_was_pressed = c_pressed

func update_timer_display():
	var time_left = max(0, collapse_timer.time_left)
	
	if game_won:
		hud.set_timer_text("VICTORY!")
		hud.hide_progress_bar()
	elif game_over:
		hud.set_timer_text("GAME OVER")
		hud.hide_progress_bar()
	elif is_processing_collapse:
		hud.set_timer_text("COLLAPSING...")
		hud.hide_progress_bar()
	else:
		hud.set_timer_text("Next collapse: %.1fs" % time_left)
		hud.set_collapse_progress(time_left, current_collapse_max_time)

func start_collapse_timer():
	var random_time = randf_range(COLLAPSE_MIN_TIME, COLLAPSE_MAX_TIME)
	current_collapse_max_time = random_time
	collapse_timer.start(random_time)
	hud.show_progress_bar()
	hud.reset_progress_bar()

func trigger_collapse():
	# Prevent re-entry
	if is_processing_collapse or game_over or game_won:
		return
	
	if particles_node.particles.size() == 0:
		return
	
	is_processing_collapse = true
	
	# Pick survivor
	var all_particles = particles_node.particles.duplicate()
	var survivor_index = randi() % all_particles.size()
	var survivor = all_particles[survivor_index]
	
	# Play effects on other particles (they get destroyed)
	for i in range(all_particles.size()):
		if i != survivor_index:
			dissolve_particle(all_particles[i])
	
	# Play effect on survivor
	stabilize_particle(survivor)
	screen_shake(2.0, 0.2)
	
	# Check result immediately
	var zone_result = check_zone(survivor.position)
	
	match zone_result:
		"green":
			game_won = true
			hud.set_status_text("QUANTUM STATE STABILIZED! YOU WIN!", Color(0.31, 1, 0.4))
			create_flash_overlay(Color(0, 1, 0, 0.15), 0.8)
			VFXSpawner.spawn_burst(survivor.global_position, Color.GREEN)
			screen_shake(2.5, 0.4)
			GameManager.complete_current_level()
		
		"red":
			game_over = true
			hud.set_status_text("COLLAPSED IN DANGER ZONE! GAME OVER!", Color(1, 0.2, 0.2))
			create_flash_overlay(Color(1, 0, 0, 0.15), 0.8)
			VFXSpawner.spawn_burst(survivor.global_position, Color.RED)
			screen_shake(2.0, 0.3)
		
		_:
			# Neutral collapse - respawn
			hud.set_status_text("Particle survived! Respawning...", Color(0.7, 0.7, 0.7))
			
			# Wait for dissolve animation to finish, then respawn
			await get_tree().create_timer(0.5).timeout
			
			# Clean up dissolved particles and respawn
			particles_node.respawn_after_collapse(survivor)
			
			# Clear status after delay
			await get_tree().create_timer(1.0).timeout
			if not game_over and not game_won:
				hud.clear_status()
			
			# Reset for next collapse
			is_processing_collapse = false
			start_collapse_timer()

func dissolve_particle(particle):
	if not is_instance_valid(particle):
		return
	
	var color = particle.base_color if not particle.is_survived else particle.survived_color
	VFXSpawner.spawn_dissolve(particle.global_position, color)
	
	var tween = create_tween()
	tween.tween_method(particle.set_fade, particle.fade_alpha, 0.0, 0.3)
	tween.parallel().tween_property(particle, "scale", Vector2(0.3, 0.3), 0.3)
	
	# Mark for cleanup after animation
	tween.tween_callback(particle.queue_free)

func stabilize_particle(particle):
	if not is_instance_valid(particle):
		return
	
	VFXSpawner.spawn_stabilize(particle.global_position)
	
	particle.set_fade(1.0)
	particle.scale = Vector2(1.0, 1.0)
	
	# Animate survivor ring
	particle.ring_alpha = 0.0
	particle.queue_redraw()
	
	var ring_tween = create_tween()
	ring_tween.tween_property(particle, "ring_alpha", 1.0, 0.3)
	ring_tween.tween_property(particle, "ring_alpha", 0.0, 0.3)
	
	# Scale pulse
	var scale_tween = create_tween()
	scale_tween.tween_property(particle, "scale", Vector2(1.2, 1.2), 0.3)
	scale_tween.tween_property(particle, "scale", Vector2(1.0, 1.0), 0.3)

func check_zone(pos: Vector2) -> String:
	if green_zones:
		var green_cell = green_zones.local_to_map(pos)
		if green_zones.get_cell_source_id(green_cell) != -1:
			return "green"
	
	if red_zones:
		var red_cell = red_zones.local_to_map(pos)
		if red_zones.get_cell_source_id(red_cell) != -1:
			return "red"
	
	return "neutral"

func screen_shake(intensity: float = 3.0, duration: float = 0.3):
	if camera == null:
		return
	
	var original_offset = camera.offset
	var tween = create_tween()
	
	for i in range(6):
		var dampen = 1.0 - (float(i) / 6.0)
		var offset = Vector2(randf() * 2 - 1, randf() * 2 - 1) * intensity * dampen
		tween.tween_property(camera, "offset", offset, duration / 6)
	
	tween.tween_property(camera, "offset", original_offset, duration / 6)

func create_flash_overlay(color: Color, duration: float = 0.5):
	var flash = ColorRect.new()
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if hud and hud.has_node("UI"):
		hud.get_node("UI").add_child(flash)
	else:
		add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_callback(func(): flash.queue_free())

func restart_level():
	game_over = false
	game_won = false
	is_processing_collapse = false
	hud.clear_status()
	hud.set_timer_text("Next collapse: --")
	particles_node.reset()
	start_collapse_timer()
