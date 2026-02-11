extends Node2D

# Built-in textures using GradientTexture2D
var glow_texture: GradientTexture2D
var ring_texture: GradientTexture2D

func _ready():
	create_textures()
	setup_particles()
	play_effect()

func create_textures():
	# Soft glow circle for particles
	glow_texture = GradientTexture2D.new()
	glow_texture.gradient = Gradient.new()
	glow_texture.gradient.colors = [Color.WHITE, Color.TRANSPARENT]
	glow_texture.gradient.offsets = [0.5, 1.0]
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.width = 64
	glow_texture.height = 64
	
	# Ring texture for shockwave
	ring_texture = GradientTexture2D.new()
	ring_texture.gradient = Gradient.new()
	ring_texture.gradient.colors = [Color.TRANSPARENT, Color.WHITE, Color.TRANSPARENT]
	ring_texture.gradient.offsets = [0.0, 0.5, 1.0]
	ring_texture.fill = GradientTexture2D.FILL_RADIAL
	ring_texture.width = 128
	ring_texture.height = 128

func setup_particles():
	# Setup expanding ring
	var ring = $ExpandingRing
	if ring:
		ring.texture = ring_texture
	
	# Setup spark burst
	var sparks = $Sparks
	if sparks:
		sparks.texture = glow_texture

func play_effect():
	# Trigger all particle systems
	for child in get_children():
		if child is GPUParticles2D or child is CPUParticles2D:
			child.emitting = true
	
	# Auto-cleanup after effect completes
	await get_tree().create_timer(1.0).timeout
	queue_free()
