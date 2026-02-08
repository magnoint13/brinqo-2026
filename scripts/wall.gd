extends StaticBody2D
class_name Wall

@export var width: float = 20.0
@export var height: float = 200.0

func _ready():
	_add_collision_shape()
	_add_visual()

func _add_collision_shape():
	for child in get_children():
		if child is CollisionShape2D:
			return
	
	var shape = RectangleShape2D.new()
	shape.size = Vector2(width, height)
	
	var col = CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2.ZERO
	add_child(col)

func _add_visual():
	for child in get_children():
		if child is Polygon2D:
			return
	
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-width/2, -height/2),
		Vector2(width/2, -height/2),
		Vector2(width/2, height/2),
		Vector2(-width/2, height/2)
	])
	poly.color = Color(0.54, 0.54, 0.6)
	add_child(poly)
