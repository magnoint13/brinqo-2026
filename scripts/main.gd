extends Node2D

const BALL_RADIUS = 8.0
const BALL_SPEED = 300.0
const COLLAPSE_MIN_TIME = 7.0
const COLLAPSE_MAX_TIME = 15.0
const COLLAPSE_ANIM_DURATION = 1.0
const RESPAWN_DURATION = 1.5

@onready var particles_node = $Particles
@onready var collapse_timer = $CollapseTimer
@onready var respawn_timer = $RespawnTimer
@onready var animation_timer = $AnimationTimer
@onready var camera = $Camera2D
@onready var walls = $Walls
@onready var zones_container = $Zones
@onready var hud = $HUD

var game_over = false
var game_won = false
var is_collapsing = false
var is_respawning = false
var selected_particle = null
var collapse_particles = []

func _ready():
	randomize()
	collapse_timer.timeout.connect(_on_collapse_timeout)
	respawn_timer.timeout.connect(_on_respawn_timeout)
	animation_timer.timeout.connect(_on_animation_timeout)
	
	create_zones()
	
	start_collapse_timer()

func _process(delta):
	if game_over or game_won:
		update_particles_visual(delta)
		return
	
	update_particles_visual(delta)
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
	elif game_over:
		hud.set_timer_text("GAME OVER")
	elif is_respawning:
		hud.set_timer_text("NEUTRAL COLLAPSE")
	else:
		hud.set_timer_text("Next collapse: %.1fs" % time_left)

func start_collapse_timer():
	var random_time = randf_range(COLLAPSE_MIN_TIME, COLLAPSE_MAX_TIME)
	collapse_timer.start(random_time)

func _on_collapse_timeout():
	if game_over or game_won:
		return
	
	is_collapsing = true
	animation_timer.start(COLLAPSE_ANIM_DURATION)
	
	if particles_node.particles.size() > 0:
		var chosen_index = randi() % particles_node.particles.size()
		selected_particle = particles_node.particles[chosen_index]
		create_collapse_effect(selected_particle)

func _on_animation_timeout():
	if not is_collapsing:
		return
	
	is_collapsing = false
	
	if selected_particle == null:
		return
	
	var zone_result = check_zone(selected_particle.position)
	
	if zone_result == "green":
		game_won = true
		hud.set_status_text("QUANTUM STATE STABILIZED! YOU WIN!", Color(0.31, 1, 0.4))
		create_explosion(selected_particle.position, Color.GREEN)
		GameManager.complete_current_level()
	elif zone_result == "red":
		game_over = true
		hud.set_status_text("COLLAPSED IN DANGER ZONE! GAME OVER!", Color(1, 0.2, 0.2))
		create_explosion(selected_particle.position, Color.RED)
	else:
		handle_neutral_collapse(selected_particle)

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
	for child in zones_container.get_children():
		if child is Zone:
			var zone_rect = Rect2(child.position, child.size)
			if zone_rect.has_point(pos):
				if child.zone_type == Zone.ZoneType.GREEN:
					return "green"
				elif child.zone_type == Zone.ZoneType.RED:
					return "red"
	
	return "neutral"

func create_zones():
	if not has_node("Zones"):
		zones_container = Node2D.new()
		zones_container.name = "Zones"
		add_child(zones_container)
		move_child(zones_container, 1)
	else:
		zones_container = $Zones

func create_border(pos: Vector2, size: Vector2, color: Color) -> Node2D:
	var border = Node2D.new()
	border.position = pos
	
	# Top line
	var top = Line2D.new()
	top.add_point(Vector2(0, 0))
	top.add_point(Vector2(size.x, 0))
	top.width = 3
	top.default_color = color
	border.add_child(top)
	
	# Bottom line
	var bottom = Line2D.new()
	bottom.add_point(Vector2(0, size.y))
	bottom.add_point(Vector2(size.x, size.y))
	bottom.width = 3
	bottom.default_color = color
	border.add_child(bottom)
	
	# Left line
	var left = Line2D.new()
	left.add_point(Vector2(0, 0))
	left.add_point(Vector2(0, size.y))
	left.width = 3
	left.default_color = color
	border.add_child(left)
	
	# Right line
	var right = Line2D.new()
	right.add_point(Vector2(size.x, 0))
	right.add_point(Vector2(size.x, size.y))
	right.width = 3
	right.default_color = color
	border.add_child(right)
	
	return border


func create_collapse_effect(_particle):
	pass

func create_explosion(pos: Vector2, color: Color):
	for i in range(20):
		var p = _create_particle(pos, color)
		add_child(p)
		collapse_particles.append(p)

func _create_particle(pos: Vector2, color: Color) -> Node2D:
	var p = Node2D.new()
	p.position = pos
	
	var sprite = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		points.append(Vector2(cos(angle), sin(angle)) * 4)
	sprite.polygon = points
	sprite.color = color
	p.add_child(sprite)
	
	var vel = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	p.set_meta("velocity", vel)
	p.set_meta("life", 1.0)
	p.set_meta("color", color)
	
	return p

func update_particles_visual(delta):
	# Filter out freed instances first
	collapse_particles = collapse_particles.filter(func(x): return is_instance_valid(x))
	
	for p in collapse_particles:
		if not is_instance_valid(p):
			continue
		var life = p.get_meta("life") - delta
		p.set_meta("life", life)
		
		var vel = p.get_meta("velocity")
		p.position += vel * delta
		vel *= 0.95
		p.set_meta("velocity", vel)
		
		p.scale = Vector2.ONE * life
		
		if life <= 0:
			p.queue_free()
	
	collapse_particles = collapse_particles.filter(func(x): return is_instance_valid(x))

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
