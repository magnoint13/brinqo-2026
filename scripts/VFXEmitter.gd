extends Node2D
class_name VFXEmitter

@export var auto_play: bool = true
@export var destroy_on_finish: bool = true
@export var lifetime_override: float = -1.0  # -1 = use particle lifetime

var particle_systems: Array[Node] = []

func _ready():
	# Collect all particle systems
	for child in get_children():
		if child is GPUParticles2D or child is CPUParticles2D:
			particle_systems.append(child)
	
	if auto_play:
		play()

func play():
	# Start all particle systems
	for ps in particle_systems:
		if ps is GPUParticles2D or ps is CPUParticles2D:
			ps.emitting = true
	
	# Auto-destroy after lifetime
	if destroy_on_finish:
		var max_lifetime = get_max_lifetime()
		await get_tree().create_timer(max_lifetime).timeout
		queue_free()

func stop():
	for ps in particle_systems:
		if ps is GPUParticles2D or ps is CPUParticles2D:
			ps.emitting = false

func get_max_lifetime() -> float:
	if lifetime_override > 0:
		return lifetime_override
	
	var max_life = 1.0
	for ps in particle_systems:
		if ps is GPUParticles2D or ps is CPUParticles2D:
			max_life = max(max_life, ps.lifetime)
	return max_life

func set_color(color: Color):
	# Try to set color on all particle systems
	for ps in particle_systems:
		if ps is GPUParticles2D and ps.process_material is ParticleProcessMaterial:
			var mat = ps.process_material as ParticleProcessMaterial
			mat.color = color
		elif ps is CPUParticles2D:
			ps.color = color
