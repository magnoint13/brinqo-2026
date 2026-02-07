extends CharacterBody2D

var is_survived: bool = false
var fade_alpha: float = 1.0

const RADIUS: float = 8.0

func setup(is_new: bool = true):
	is_survived = not is_new
	fade_alpha = 0.0 if is_new else 1.0
	velocity = Vector2.ZERO
	queue_redraw()

func _ready():
	# Initialize physics after node is in tree
	move_and_slide()

func set_survived(value: bool):
	is_survived = value
	fade_alpha = 1.0
	queue_redraw()

func _draw():
	var color: Color = Color(1.0, 0.84, 0.0) if is_survived else Color(0.39, 0.59, 1.0)
	color.a = fade_alpha
	
	draw_circle(Vector2.ZERO, RADIUS, color)
	draw_circle(Vector2.ZERO, RADIUS * 0.6, Color.WHITE)
	
	if is_survived:
		draw_arc(Vector2.ZERO, RADIUS + 2, 0, TAU, 16, Color(1.0, 0.84, 0.0, fade_alpha), 2.0)

func set_fade(value: float):
	fade_alpha = value
	queue_redraw()
