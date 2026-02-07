extends Node2D

const BALL_RADIUS = 8.0
const BALL_SPEED = 300.0
const COLLAPSE_MIN_TIME = 7.0
const COLLAPSE_MAX_TIME = 15.0
const COLLAPSE_ANIM_DURATION = 1.0
const RESPAWN_DURATION = 1.5

@onready var particles_node = $Particles
@onready var timer_label = $CanvasLayer/UI/TimerLabel
@onready var status_label = $CanvasLayer/UI/StatusLabel
@onready var restart_button = $CanvasLayer/UI/RestartButton
@onready var collapse_timer = $CollapseTimer
@onready var respawn_timer = $RespawnTimer
@onready var animation_timer = $AnimationTimer
@onready var camera = $Camera2D
@onready var walls = $Walls/Walls

var game_over = false
var game_won = false
var is_collapsing = false
var is_respawning = false
var selected_particle = null
var collapse_particles = []
var zones_container: Node2D

func _ready():
	randomize()
	restart_button.pressed.connect(_on_restart_pressed)
	collapse_timer.timeout.connect(_on_collapse_timeout)
	respawn_timer.timeout.connect(_on_respawn_timeout)
	animation_timer.timeout.connect(_on_animation_timeout)
	
	# Create zones FIRST (before walls so they render behind)
	create_zones()
	create_walls()
	
	start_collapse_timer()

func _process(delta):
	if game_over or game_won:
		update_particles_visual(delta)
		return
	
	if is_collapsing or is_respawning:
		update_particles_visual(delta)
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
	timer_label.text = "Next collapse: %.1fs" % time_left

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
		status_label.text = "QUANTUM STATE STABILIZED! YOU WIN!"
		status_label.add_theme_color_override("font_color", Color(0.31, 1, 0.4))
		timer_label.text = "VICTORY!"
		create_explosion(selected_particle.position, Color.GREEN)
	elif zone_result == "red":
		game_over = true
		status_label.text = "COLLAPSED IN DANGER ZONE! GAME OVER!"
		status_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		timer_label.text = "GAME OVER"
		create_explosion(selected_particle.position, Color.RED)
	else:
		handle_neutral_collapse(selected_particle)

func handle_neutral_collapse(survived):
	status_label.text = "Particle survived! Respawning..."
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	timer_label.text = "NEUTRAL COLLAPSE"
	
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
	
	await get_tree().create_timer(2.0).timeout
	if not game_over and not game_won:
		status_label.text = ""

func check_zone(pos: Vector2) -> String:
	var green_zone = Rect2(650, 250, 100, 100)
	if green_zone.has_point(pos):
		return "green"
	
	var red_zones = [
		Rect2(200, 100, 150, 100),
		Rect2(400, 350, 120, 150),
		Rect2(550, 50, 180, 120),
		Rect2(250, 400, 140, 120)
	]
	
	for zone in red_zones:
		if zone.has_point(pos):
			return "red"
	
	return "neutral"

func create_zones():
	zones_container = Node2D.new()
	zones_container.name = "Zones"
	add_child(zones_container)
	# Move zones to be drawn AFTER background (index 1) but before other elements
	move_child(zones_container, 1)
	
	# Green zone - filled
	var green = ColorRect.new()
	green.position = Vector2(650, 250)
	green.size = Vector2(100, 100)
	green.color = Color(0.2, 1.0, 0.2, 0.4)
	zones_container.add_child(green)
	
	# Green zone - border (using a panel or multiple lines)
	var green_border = create_border(Vector2(650, 250), Vector2(100, 100), Color(0.2, 1.0, 0.2))
	zones_container.add_child(green_border)
	
	# Red zones
	var red_positions = [
		Vector2(200, 100),
		Vector2(400, 350),
		Vector2(550, 50),
		Vector2(250, 400)
	]
	var red_sizes = [
		Vector2(150, 100),
		Vector2(120, 150),
		Vector2(180, 120),
		Vector2(140, 120)
	]
	
	for i in range(red_positions.size()):
		var red = ColorRect.new()
		red.position = red_positions[i]
		red.size = red_sizes[i]
		red.color = Color(1.0, 0.2, 0.2, 0.4)
		zones_container.add_child(red)
		
		var red_border = create_border(red_positions[i], red_sizes[i], Color(1.0, 0.2, 0.2))
		zones_container.add_child(red_border)

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

func create_walls():
	var wall_positions = [
		Rect2(300, 150, 20, 200),
		Rect2(500, 250, 20, 180)
	]
	
	for wp in wall_positions:
		var wall = StaticBody2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(wp.size.x, wp.size.y)
		
		var col = CollisionShape2D.new()
		col.shape = shape
		col.position = wp.get_center()
		
		wall.add_child(col)
		walls.add_child(wall)
		
		var vis = _create_wall_visual(wp)
		walls.add_child(vis)

func _create_wall_visual(rect: Rect2) -> Node2D:
	var node = Node2D.new()
	node.position = rect.get_center()
	
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-rect.size.x/2, -rect.size.y/2),
		Vector2(rect.size.x/2, -rect.size.y/2),
		Vector2(rect.size.x/2, rect.size.y/2),
		Vector2(-rect.size.x/2, rect.size.y/2)
	])
	poly.color = Color(0.54, 0.54, 0.6)
	node.add_child(poly)
	
	return node

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

func _on_restart_pressed():
	game_over = false
	game_won = false
	is_collapsing = false
	is_respawning = false
	selected_particle = null
	status_label.text = ""
	timer_label.text = "Next collapse: --"
	particles_node.reset()
	start_collapse_timer()
