extends ColorRect
class_name Zone

enum ZoneType { RED, GREEN }

@export var zone_type: ZoneType = ZoneType.RED

func _ready():
	if zone_type == ZoneType.GREEN:
		color = Color(0.2, 1.0, 0.2, 0.4)
	else:
		color = Color(1.0, 0.2, 0.2, 0.4)
