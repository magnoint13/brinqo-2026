extends Node2D

const BALL_RADIUS = 8.0
const BALL_SPEED = 300.0
const COLLAPSE_MIN_TIME = 7.0
const COLLAPSE_MAX_TIME = 15.0
const COLLAPSE_ANIM_DURATION = 0.8
const RESPAWN_DURATION = 1.5

@onready var particles_node = $Particles
@onready var collapse_timer = $CollapseTimer
@onready var respawn_timer = $RespawnTimer
@onready var animation_timer = $AnimationTimer
@onready var camera = $Camera2D
@onready var walls = $Walls/TileMapLayer
@onready var red_zones = $RedZone/TileMapLayer
@onready var green_zones = $GreenZone/TileMapLayer
@onready var hud = $HUD

var game_over = false
var game_won = false
var is_collapsing = false
var is_respawning = false
var selected_particle = null

var current_collapse_max_time: float = 15.0

func _ready():
	randomize()
	collapse_timer.timeout.connect(_on_collapse_timeout)
	respawn_timer.timeout.connect(_on_respawn_timeout)
	animation_timer.timeout.connect(_on_animation_timeout)
	
	start_collapse_timer()
	hud.show_progress_bar()

func _process(delta):
	if game_over or game_won:
		return
	
	handle_input(delta)
	update_timer_display()

func handle_input(delta: float):
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

func update_timer_display():
	var time_left = max(0, collapse_timer.time_left)
	if game_won:
		hud.set_timer_text("VICTORY!")
		hud.hide_progress_bar()
	elif game_over:
		hud.set_timer_text("GAME OVER")
		hud.hide_progress_bar()
	elif is_respawning:
		hud.set_timer_text("NEUTRAL COLLAPSE")
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

func _on_collapse_timeout():
	if game_over or game_won:
		return
	
	is_collapsing = true
	animation_timer.start(COLLAPSE_ANIM_DURATION)
	
	if particles_node.particles.size() > 0:
		var chosen_index = randi() % particles_node.particles.size()
		selected_particle = particles_node.particles[chosen_index]
		
		# PHASE 1: Subtle screen shake
		screen_shake(2.0, 0.2)
		
		# PHASE 2: Dissolve effect on non-selected particles (they're being destroyed)
		for i in range(particles_node.particles.size()):
			if i != chosen_index:
				dissolve_particle(particles_node.particles[i])
		
		# PHASE 3: Gentle stabilization effect on selected particle
		stabilize_particle(selected_particle)

func _on_animation_timeout():
	if not is_collapsing:
		return
	
	is_collapsing = false
	
	if selected_particle == null:
		return
	
	var zone_result = check_zone(selected_particle.position)
	
	match zone_result:
		"green":
			game_won = true
			victory_effects()
		"red":
			game_over = true
			defeat_effects()
		_:
			handle_neutral_collapse(selected_particle)

func victory_effects():
	hud.set_status_text("QUANTUM STATE STABILIZED! YOU WIN!", Color(0.31, 1, 0.4))
	
	# Gentle green flash
	create_flash_overlay(Color(0, 1, 0, 0.15), 0.8)
	
	# Use VFX scene for green burst
	VFXSpawner.spawn_burst(selected_particle.global_position, Color.GREEN)
	
	# Light screen shake for victory
	screen_shake(2.5, 0.4)
	
	GameManager.complete_current_level()

func defeat_effects():
	hud.set_status_text("COLLAPSED IN DANGER ZONE! GAME OVER!", Color(1, 0.2, 0.2))
	
	# Subtle red flash
	create_flash_overlay(Color(1, 0, 0, 0.15), 0.8)
	
	# Use VFX scene for red burst
	VFXSpawner.spawn_burst(selected_particle.global_position, Color.RED)
	
	# Light screen shake
	screen_shake(2.0, 0.3)

func handle_neutral_collapse(survived):
	hud.set_status_text("Particle survived! Respawning...", Color(0.7, 0.7, 0.7))
	
	survived.set_survived(true)
	particles_node.clear_non_survived()
	
	respawn_timer.start(0.5)
	is_respawning = true

func _on_respawn_timeout():
	particles_node.respawn_two_particles(Vector2.ZERO)
	is_respawning = false
	start_collapse_timer()
	
	# Fade survived particle back to blue after respawn completes
	var survived = particles_node.get_survived_particle()
	if survived:
		var tween = create_tween()
		tween.tween_callback(survived.set_survived.bind(false)).set_delay(1.5)
	
	# Clear status message quickly since player can keep moving
	await get_tree().create_timer(1.0).timeout
	if not game_over and not game_won:
		hud.clear_status()

func check_zone(pos: Vector2) -> String:
	# Check green zones first (win condition)
	if green_zones:
		var green_cell = green_zones.local_to_map(pos)
		if green_zones.get_cell_source_id(green_cell) != -1:
			return "green"
	
	# Check red zones (lose condition)
	if red_zones:
		var red_cell = red_zones.local_to_map(pos)
		if red_zones.get_cell_source_id(red_cell) != -1:
			return "red"
	
	return "neutral"

func create_border(pos: Vector2, size: Vector2, color: Color) -> Node2D:
	var border = Node2D.new()
	border.position = pos
	
	var top = Line2D.new()
	top.add_point(Vector2(0, 0))
	top.add_point(Vector2(size.x, 0))
	top.width = 3
	top.default_color = color
	border.add_child(top)
	
	var bottom = Line2D.new()
	bottom.add_point(Vector2(0, size.y))
	bottom.add_point(Vector2(size.x, size.y))
	bottom.width = 3
	bottom.default_color = color
	border.add_child(bottom)
	
	var left = Line2D.new()
	left.add_point(Vector2(0, 0))
	left.add_point(Vector2(0, size.y))
	left.width = 3
	left.default_color = color
	border.add_child(left)
	
	var right = Line2D.new()
	right.add_point(Vector2(size.x, 0))
	right.add_point(Vector2(size.x, size.y))
	right.width = 3
	right.default_color = color
	border.add_child(right)
	
	return border

func screen_shake(intensity: float = 3.0, duration: float = 0.3):
	if camera == null:
		return
	
	var original_offset = camera.offset
	var tween = create_tween()
	
	for i in range(6):
		var dampen = 1.0 - (float(i) / 6.0)
		var offset = Vector2(
			randf() * 2 - 1,
			randf() * 2 - 1
		) * intensity * dampen
		
		tween.tween_property(camera, "offset", offset, duration / 6)
	
	tween.tween_property(camera, "offset", original_offset, duration / 6)

func dissolve_particle(particle):
	# Spawn VFX scene for dissolve effect
	var color = particle.base_color if !particle.is_survived else particle.survived_color
	VFXSpawner.spawn_dissolve(particle.global_position, color)
	
	# Tween the particle fading out
	var tween = create_tween()
	tween.tween_property(particle, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(particle, "scale", Vector2(0.3, 0.3), 0.3)

func stabilize_particle(particle):
	# Spawn VFX scene for stabilization effect
	VFXSpawner.spawn_stabilize(particle.global_position)
	
	# Animate the yellow ring
	var ring_tween = create_tween()
	particle.ring_alpha = 0.0
	particle.queue_redraw()
	
	ring_tween.tween_property(particle, "ring_alpha", 1.0, 0.3)
	ring_tween.parallel().tween_callback(particle.queue_redraw)
	ring_tween.tween_property(particle, "ring_alpha", 0.0, 0.3)
	ring_tween.parallel().tween_callback(particle.queue_redraw)
	
	# Gentle scale pulse
	var tween2 = create_tween()
	tween2.tween_property(particle, "scale", Vector2(1.2, 1.2), 0.3)
	tween2.tween_property(particle, "scale", Vector2(1.0, 1.0), 0.3)

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
	is_collapsing = false
	is_respawning = false
	selected_particle = null
	hud.clear_status()
	hud.set_timer_text("Next collapse: --")
	particles_node.reset()
	start_collapse_timer()
