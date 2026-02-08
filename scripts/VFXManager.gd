extends WorldEnvironment

# VFX Helper Functions

func trigger_screen_shake(camera: Camera2D, intensity: float = 3.0, duration: float = 0.3):
	if camera == null:
		return
	
	var original_offset = camera.offset
	var tween = create_tween()
	
	# 6 quick shakes with dampening
	for i in range(6):
		var dampen = 1.0 - (float(i) / 6.0)
		var offset = Vector2(
			randf() * 2 - 1,
			randf() * 2 - 1
		) * intensity * dampen
		
		tween.tween_property(camera, "offset", offset, duration / 6)
	
	# Return to original
	tween.tween_property(camera, "offset", original_offset, duration / 6)

func create_flash_overlay(color: Color, duration: float = 0.5) -> ColorRect:
	var flash = ColorRect.new()
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	get_tree().root.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_callback(func(): flash.queue_free())
	
	return flash

func pulse_node(node: Node2D, scale_mult: float = 1.3, duration: float = 0.1, cycles: int = 3):
	if node == null:
		return
	
	var original_scale = node.scale
	var tween = create_tween()
	
	for i in range(cycles):
		tween.tween_property(node, "scale", original_scale * scale_mult, duration)
		tween.tween_property(node, "scale", original_scale, duration)

func glitch_node(node: Node2D, intensity: float = 5.0, duration: float = 0.1):
	if node == null:
		return
	
	var original_position = node.position
	var tween = create_tween()
	
	# 3 quick glitch frames
	for i in range(3):
		var offset = Vector2(
			randf() * 2 - 1,
			randf() * 2 - 1
		) * intensity
		tween.tween_property(node, "position", original_position + offset, duration / 3)
	
	tween.tween_property(node, "position", original_position, duration / 3)
