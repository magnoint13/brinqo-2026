# VFX Manager - Preload and spawn VFX scenes
# Usage: VFXManager.spawn_explosion(position, color)

extends Node

# Preload VFX scenes
var explosion_vfx = preload("res://scenes/vfx/ExplosionVFX.tscn")
var burst_vfx = preload("res://scenes/vfx/BurstVFX.tscn")
var dissolve_vfx = preload("res://scenes/vfx/DissolveVFX.tscn")
var stabilize_vfx = preload("res://scenes/vfx/StabilizeVFX.tscn")

# Track active effects
var active_effects: Array[Node] = []

func spawn_explosion(pos: Vector2, color: Color = Color.WHITE) -> Node:
	var effect = explosion_vfx.instantiate()
	effect.position = pos
	get_tree().current_scene.add_child(effect)
	effect.set_color(color)
	active_effects.append(effect)
	
	# Auto-remove from tracking when done
	effect.tree_exiting.connect(func(): active_effects.erase(effect))
	
	return effect

func spawn_burst(pos: Vector2, color: Color = Color.WHITE) -> Node:
	var effect = burst_vfx.instantiate()
	effect.position = pos
	get_tree().current_scene.add_child(effect)
	effect.set_color(color)
	active_effects.append(effect)
	
	effect.tree_exiting.connect(func(): active_effects.erase(effect))
	
	return effect

func spawn_dissolve(pos: Vector2, color: Color = Color(0.7, 0.7, 0.8)) -> Node:
	var effect = dissolve_vfx.instantiate()
	effect.position = pos
	get_tree().current_scene.add_child(effect)
	effect.set_color(color)
	active_effects.append(effect)
	
	effect.tree_exiting.connect(func(): active_effects.erase(effect))
	
	return effect

func spawn_stabilize(pos: Vector2) -> Node:
	var effect = stabilize_vfx.instantiate()
	effect.position = pos
	get_tree().current_scene.add_child(effect)
	active_effects.append(effect)
	
	effect.tree_exiting.connect(func(): active_effects.erase(effect))
	
	return effect

func clear_all_effects():
	for effect in active_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	active_effects.clear()
