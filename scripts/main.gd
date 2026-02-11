extends Node2D

const BALL_RADIUS = 8.0
const BALL_SPEED = 300.0
const COLLAPSE_MIN_TIME = 7.0
const COLLAPSE_MAX_TIME = 15.0
const ROTATION_SPEED = 180.0

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

# Input tracking for button sync
var c_key_was_pressed = false
var r_key_was_pressed = false

func _ready():
	randomize()
	collapse_timer.timeout.connect(trigger_collapse)
	start_collapse_timer()
	hud.show_progress_bar()
	hud.setup_action_buttons(self)

func _process(delta):
	if game_over or game_won:
		return
	
	handle_input(delta)
	update_timer_display()

func handle_input(delta: float):
	# Handle Rotate button (R key) - sync button state with key state
	var is_r_pressed = Input.is_key_pressed(KEY_R)
	if is_r_pressed != r_key_was_pressed:
		hud.rotate_button.button_pressed = is_r_pressed
		hud.is_rotating = is_r_pressed  # Sync rotation state
		hud.set_rotate_button_visual_pressed(is_r_pressed)  # Update visual
		if is_r_pressed:
			hud.rotate_button.button_down.emit()
		else:
			hud.rotate_button.button_up.emit()
	r_key_was_pressed = is_r_pressed
	
	# Rotation logic - check button state (works for both key and click)
	if hud.is_rotating:
		var rotation_direction = 0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			rotation_direction = 1  # Clockwise
		elif Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			rotation_direction = -1  # Counter-clockwise
		
		if rotation_direction != 0:
			particles_node.rotate_particles(delta, rotation_direction, ROTATION_SPEED, walls)
	else:
		# Normal movement mode
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
	
	# Handle Collapse button (C key) - sync button state with key state
	var is_c_pressed = Input.is_key_pressed(KEY_C) or Input.is_key_pressed(KEY_SPACE)
	if is_c_pressed != c_key_was_pressed:
		hud.collapse_button.button_pressed = is_c_pressed
		hud.set_collapse_button_visual_pressed(is_c_pressed)  # Update visual
		if is_c_pressed:
			hud.collapse_button.button_down.emit()
			hud.collapse_button.pressed.emit()  # Trigger the action!
		else:
			hud.collapse_button.button_up.emit()
	c_key_was_pressed = is_c_pressed

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
		hud.set_timer_text("Coherence time: %.1fs" % time_left)
		hud.set_collapse_progress(time_left, current_collapse_max_time)

func start_collapse_timer():
	var random_time = randf_range(COLLAPSE_MIN_TIME, COLLAPSE_MAX_TIME)
	current_collapse_max_time = random_time
	collapse_timer.start(random_time)
	hud.show_progress_bar()
	hud.reset_progress_bar()

# Called by collapse button (both keyboard and mouse)
func trigger_collapse_manual():
	if is_processing_collapse or game_over or game_won:
		return
	collapse_timer.stop()
	trigger_collapse()

func trigger_collapse():
	# Prevent re-entry
	if is_processing_collapse or game_over or game_won:
		return
	
	if particles_node.particles.size() == 0:
		return
	
	is_processing_collapse = true
	
	# Fade out connection lines immediately
	particles_node.fade_out_lines(0.2)
	
	# Get movement direction for wave collapse bias
	var direction = particles_node.last_movement_direction
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT  # Default direction
	
	var all_particles = particles_node.particles.duplicate()
	
	# PHASE 1: Animate all particles to wave state
	for particle in all_particles:
		if is_instance_valid(particle):
			particle.to_wave_animated()
	
	# Wait for wave animation
	await get_tree().create_timer(0.25).timeout
	
	# PHASE 2: Pick survivor first, then only move the survivor
	var survivor_index = randi() % all_particles.size()
	var survivor = all_particles[survivor_index]
	
	# Only generate random position for the survivor particle
	if is_instance_valid(survivor):
		var new_pos = survivor.generate_random_pos(direction)
		survivor.global_position = new_pos
	# Non-survivor particles stay at their current positions (no movement)
	
	# PHASE 3: Animate all particles to particle state
	for particle in all_particles:
		if is_instance_valid(particle):
			particle.to_particle_animated()
	
	# Wait for particle animation
	await get_tree().create_timer(0.25).timeout
	
	# PHASE 4: Dissolve non-survivors
	for i in range(all_particles.size()):
		if i != survivor_index and is_instance_valid(all_particles[i]):
			dissolve_particle(all_particles[i])
	
	# PHASE 5: Stabilize survivor and start auto-revert timer
	if is_instance_valid(survivor):
		stabilize_particle(survivor)
		# Start auto-revert timer (2 seconds to revert to wave state)
		var timer = survivor.get_node("CollapsedTimer")
		if timer:
			timer.start()
		
		# Spawn ripple effect at survivor's position
		var ripple = preload("res://scripts/RippleEffect.gd").new()
		ripple.position = survivor.global_position
		add_child(ripple)
	
	screen_shake(2.0, 0.2)
	
	# Check result based on survivor's NEW position
	var zone_result = check_zone(survivor.global_position)
	
	match zone_result:
		"green":
			game_won = true
			hud.set_game_over()  # Prevent further pausing
			hud.set_status_text("QUANTUM STATE STABILIZED! YOU WIN!", Color(0.31, 1, 0.4))
			create_flash_overlay(Color(0, 1, 0, 0.15), 0.8)
			VFXSpawner.spawn_burst(survivor.global_position, Color.GREEN)
			screen_shake(2.5, 0.4)
			GameManager.complete_current_level()
		
		"red":
			game_over = true
			hud.set_game_over()  # Prevent further pausing
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
			
			# Fade in connection lines after respawn
			particles_node.fade_in_lines(0.5)
			
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
	
	VFXSpawner.spawn_dissolve(particle.global_position, particle.base_color)
	
	var tween = create_tween()
	tween.tween_method(particle.set_fade, particle.fade_alpha, 0.0, 0.3)
	tween.parallel().tween_property(particle, "scale", Vector2(0.3, 0.3), 0.3)
	
	# Mark for cleanup after animation
	tween.tween_callback(particle.queue_free)

func stabilize_particle(particle):
	if not is_instance_valid(particle):
		return
	
	particle.set_fade(1.0)
	particle.scale = Vector2(1.0, 1.0)
	
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
	hud.set_game_over(false)  # Re-enable pausing
	hud.set_timer_text("Coherence time: --")
	particles_node.reset()
	start_collapse_timer()
