extends TextureProgressBar

# Visual effects configuration
@export_group("Visual Effects")
@export var enable_pulse = true
@export var enable_shine = true
@export var glow_intensity = 0.5
@export var pulse_speed = 2.0
@export var shine_speed = 0.5

@export_group("Segmented Bar")
@export var segment_count = 20
@export var stepify = true
@export var margin = Vector2(0.12, 0.1)
@export var corner_radius = 0.1

@export_group("Border")
@export var border_thickness = 0.02
@export var border_color = Color(0, 0, 0, 0.8)

func _ready():
	# Configure shader parameters
	if material is ShaderMaterial:
		material.set_shader_parameter("enable_pulse", enable_pulse)
		material.set_shader_parameter("enable_shine", enable_shine)
		material.set_shader_parameter("glow_intensity", glow_intensity)
		material.set_shader_parameter("pulse_speed", pulse_speed)
		material.set_shader_parameter("shine_speed", shine_speed)
		material.set_shader_parameter("count", segment_count)
		material.set_shader_parameter("stepify", stepify)
		material.set_shader_parameter("margin", margin)
		material.set_shader_parameter("corner_radius", corner_radius)
		material.set_shader_parameter("border_thickness", border_thickness)
		material.set_shader_parameter("border_color", border_color)
		material.set_shader_parameter("value", value)

func _process(_delta):
	# Sync shader with current value
	if material is ShaderMaterial:
		material.set_shader_parameter("value", value)
