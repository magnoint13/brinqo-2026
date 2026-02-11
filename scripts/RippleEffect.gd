extends Node2D

# RippleEffect - Creates expanding concentric rings at a position
# Spawn this at the target position, it auto-deletes when done

@export var ring_count: int = 3
@export var ring_color: Color = Color(0.5, 0.8, 1.0, 0.6)  # Light blue
@export var max_radius: float = 120.0
@export var start_radius: float = 10.0
@export var expand_duration: float = 0.6
@export var spawn_delay: float = 0.1
@export var line_width: float = 2.5

var rings: Array[Line2D] = []
var spawn_timer: float = 0.0
var rings_spawned: int = 0
var total_duration: float

func _ready():
	total_duration = (ring_count - 1) * spawn_delay + expand_duration + 0.1
	
	# Auto-cleanup after effect completes
	await get_tree().create_timer(total_duration).timeout
	queue_free()

func _process(delta):
	# Spawn rings with delay
	if rings_spawned < ring_count:
		spawn_timer += delta
		if spawn_timer >= spawn_delay or rings_spawned == 0:
			spawn_ring()
			spawn_timer = 0.0

func spawn_ring():
	var ring = Line2D.new()
	ring.width = line_width
	ring.default_color = ring_color
	ring.antialiased = true
	ring.z_index = 10
	
	# Create circle points
	var points = []
	var segments = 32
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * start_radius)
	ring.points = points
	
	add_child(ring)
	rings.append(ring)
	rings_spawned += 1
	
	# Animate the ring expanding and fading
	var tween = create_tween()
	
	# Expand radius
	tween.parallel().tween_method(
		func(radius): update_ring_radius(ring, radius),
		start_radius,
		max_radius,
		expand_duration
	)
	
	# Fade out alpha
	var start_color = ring_color
	var end_color = ring_color
	end_color.a = 0.0
	
	tween.parallel().tween_method(
		func(color): ring.default_color = color,
		start_color,
		end_color,
		expand_duration
	)
	
	# Cleanup individual ring after animation
	tween.tween_callback(func(): 
		if is_instance_valid(ring):
			ring.queue_free()
	)

func update_ring_radius(ring: Line2D, radius: float):
	if not is_instance_valid(ring):
		return
	
	var points = []
	var segments = 32
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = points
