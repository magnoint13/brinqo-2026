extends Node2D

const BALL_RADIUS = 8.0
const BALL_SPEED = 300.0
const COLLAPSE_MIN_TIME = 7.0
const COLLAPSE_MAX_TIME = 15.0
const ROTATION_SPEED = 180.0
const SCALE_SPEED = 300.0
const RESTART_DELAY = 2.0

@onready var particles_node = $Particles
@onready var collapse_timer = $CollapseTimer
@onready var camera = $Camera2D
@onready var red_zones = $RedZone
@onready var green_zones = $GreenZone
@onready var hud = $HUD

# Simple state tracking
var game_over: bool = false
var game_won: bool = false
var is_processing_collapse: bool = false
var is_entanglement_broken: bool = false
var is_reentanglement: bool = false
var current_collapse_max_time: float = 15.0
var total_green_zones: int = 0

# Input tracking for button sync
var c_key_was_pressed = false
var r_key_was_pressed = false

# Restart timer - runs even when paused
var restart_timer: Timer

func _ready():
	randomize()
	collapse_timer.timeout.connect(break_entanglement)
	particles_node.level_main = self
	hud.setup_action_buttons(self)
	
	# Setup restart timer - runs even when game is paused
	restart_timer = Timer.new()
	restart_timer.name = "RestartTimer"
	restart_timer.wait_time = RESTART_DELAY
	restart_timer.one_shot = true
	restart_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_timer.timeout.connect(_on_restart_timer_timeout)
	add_child(restart_timer)
	
	if particles_node.particles.size() > 1:
		var n_entangled: int = 0
		for p in particles_node.particles:
			if p.is_entangled:
				n_entangled += 1
		if n_entangled > 1:
			start_collapse_timer()
			hud.show_progress_bar()
		else:
			is_entanglement_broken = true
	
	if green_zones:
		for zone in green_zones.get_children():
			if zone is TileMapLayer:
				total_green_zones += 1

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
		# rotation
		var rotation_direction = 0
		var triangle_scale = 0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			rotation_direction = 1  # Clockwise
		elif Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			rotation_direction = -1  # Counter-clockwise

		# scaling
		elif Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			triangle_scale = 1  # bigger
		elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			triangle_scale = -1  # smaller
		
		if rotation_direction != 0:
			particles_node.rotate_particles(delta, rotation_direction, ROTATION_SPEED)
		elif triangle_scale != 0:
			particles_node.scale_particles(delta, triangle_scale, SCALE_SPEED)
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
			particles_node.apply_movement(direction, BALL_SPEED * delta)
	
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
		hud.set_timer_text(tr("GAME_VICTORY"))
		hud.hide_progress_bar()
	elif game_over:
		hud.set_timer_text(tr("GAME_OVER"))
		hud.hide_progress_bar()
	elif is_entanglement_broken:
		hud.set_timer_text(tr("ENTANGLE_BREAK"))
		hud.hide_progress_bar()
	elif is_reentanglement:
		hud.set_timer_text(tr("RE_ENTANGLEMENT"))
		hud.hide_progress_bar()
	elif is_processing_collapse:
		hud.set_timer_text(tr("GAME_COLLAPSING"))
		hud.hide_progress_bar()

	elif particles_node.particles.size() > 1:
		hud.set_timer_text(tr("GAME_TIMER_FORMAT") % time_left)
		hud.set_collapse_progress(time_left, current_collapse_max_time)
	else:
		hud.set_timer_text("")
		hud.hide_progress_bar()

func start_collapse_timer():
	# Entanglement timer does not happen when there only is one particle
	if particles_node.particles.size() <= 1:
		return
	var random_time = randf_range(COLLAPSE_MIN_TIME, COLLAPSE_MAX_TIME)
	current_collapse_max_time = random_time
	collapse_timer.one_shot = true
	collapse_timer.start(random_time)
	hud.show_progress_bar()
	hud.reset_progress_bar()

func break_entanglement():
	if is_entanglement_broken:
		return
	trigger_collapse(true)

func trigger_collapse(entanglement_broken: bool = false):
	# Prevent re-entry
	if is_processing_collapse or game_over or game_won or particles_node.particles.size() == 0:
		return
		
	is_processing_collapse = true
	collapse_timer.stop()
	particles_node.collapse_all()
	
	# Fade out connection lines immediately
	particles_node.fade_out_lines(0.2)
	
	# Wait for particle animation
	await get_tree().create_timer(0.25).timeout
	screen_shake(2.0, 0.2)

	var used_green_zones = {} # dict used as set
	for p in particles_node.particles:
		var current_zone = check_zone(p.global_position)
		
		# Update zone_result with the following priorities:
		# - RED if some particle is in a red zone, looses inmediately
		if current_zone < 0:
			game_over = true
			hud.set_game_over()  # Prevent further pausing
			hud.set_status_text(tr("GAME_DEATH_REDZONE"), Color(1, 0.2, 0.2))
			create_flash_overlay(Color(1, 0, 0, 0.15), 0.8)
			#VFXSpawner.spawn_burst(survivor.global_position, Color.RED)
			screen_shake(2.0, 0.3)
			restart_timer.start()
			return
			
		# - GREEN if all the green zones are covered
		#   mark the current zone ID
		elif current_zone > 0:
			used_green_zones[current_zone] = true

	# If we didn't loose, but we didn't cover all the zones, is NEUTRAL
	if used_green_zones.size() != total_green_zones:
		# neutral - respawn
		if entanglement_broken:
			# Timer expired - always break entanglement regardless of coverage
			hud.set_status_text(tr("ENTANGLE_BREAK"), Color(0.2, 0.1, 0.7))
			particles_node.break_entanglement()
		elif used_green_zones.size() != 0:
			hud.set_status_text(tr("GAME_HINT_COVERAGE"), Color(0.2, 0.1, 0.7))
		else:
			hud.set_status_text(tr("GAME_NEUTRAL_SURVIVED"), Color(0.7, 0.7, 0.7))
		
		# Fade in connection lines after respawn
		particles_node.fade_in_lines(0.5)
		
		# Clear status after delay
		await get_tree().create_timer(2.0).timeout
		if not game_over and not game_won:
			hud.clear_status()
		
		# Reset for next collapse
		is_processing_collapse = false
		if entanglement_broken:
			is_entanglement_broken = true
		elif not is_entanglement_broken:
			start_collapse_timer()
		
	else: # green - win condition
		game_won = true
		hud.set_game_over()  # Prevent further pausing
		create_flash_overlay(Color(0, 1, 0, 0.15), 0.8)
		#VFXSpawner.spawn_burst(survivor.global_position, Color.GREEN)
		screen_shake(2.5, 0.4)
		
		# Play win sound
		var player = AudioStreamPlayer.new()
		player.stream = load("res://resources/sfx/sfx_win.wav")
		player.bus = "SFX"
		add_child(player)
		player.play()
		player.finished.connect(player.queue_free)
		
		# Wait for win sound to play (1 second delay)
		await get_tree().create_timer(1.0).timeout
		
		# Show win popup instead of auto-redirecting
		GameManager.mark_level_complete()
		hud.show_win_popup(GameManager.current_level)

# NOTE: not currently used
func dissolve_particle(particle):
	if not is_instance_valid(particle):
		return
	
	VFXSpawner.spawn_dissolve(particle.global_position, particle.base_color)
	
	var tween = create_tween()
	tween.tween_method(particle.set_fade, particle.fade_alpha, 0.0, 0.3)
	tween.parallel().tween_property(particle.visual_container, "scale", Vector2(0.3, 0.3), 0.3)
	
	# Mark for cleanup after animation
	tween.tween_callback(particle.queue_free)

# positive: green, with the zone ID (kinda)
# red: negative
# neutral: 0
func check_zone(pos: Vector2) -> int:
	if green_zones:
		var i = 1
		for zone in green_zones.get_children():
			if zone is TileMapLayer and zone.get_cell_source_id(zone.local_to_map(zone.to_local(pos))) != -1:
				return i
			i += 1
		
	if red_zones:
		for zone in red_zones.get_children():
			if zone is TileMapLayer:
				var red_cell = zone.local_to_map(zone.to_local(pos))
				if zone.get_cell_source_id(red_cell) != -1:
					return -1
			
			
	
	return 0

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

func reentangle():
	is_entanglement_broken = false
	is_reentanglement = true
	hud.set_timer_text("RE-ENTANGLEMENT!")
	get_tree().create_timer(1.0).timeout.connect(func():
		is_reentanglement = false
		start_collapse_timer()
	)

func restart_level():
	game_over = false
	game_won = false
	is_processing_collapse = false
	is_entanglement_broken = false
	hud.clear_status()
	hud.set_game_over(false)  # Re-enable pausing
	hud.set_timer_text("Coherence time: --")
	particles_node.reset()
	start_collapse_timer()

func _on_restart_timer_timeout():
	if game_over:
		get_tree().reload_current_scene()
