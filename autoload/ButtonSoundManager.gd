# SoundManager.gd - Autoload Singleton (Project Settings > Autoload)
extends Node

@export var button_sound_path: String = "res://resources/sfx/sfx_onbuttonpressed.wav"
var button_sound: AudioStream
var audio_player_scene: PackedScene # Optional: preload a pre-configured AudioStreamPlayer scene for reuse/pooling

signal button_pressed # Optional: if you want other systems to react

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # Process even when paused
	
	button_sound = load(button_sound_path)
	if not button_sound:
		push_error("Button sound not found at: " + button_sound_path)
		return
	
	# Connect to catch newly added buttons (dynamic UI)
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed) # Optional cleanup
	
	# Connect existing buttons in the scene
	call_deferred("_connect_existing_buttons")

func _connect_existing_buttons():
	_connect_buttons_recursive(get_tree().root)

func _connect_buttons_recursive(parent: Node):
	for child in parent.get_children():
		if child is BaseButton:  # BaseButton covers Button, CheckButton, etc. for broader UI sounds
			_connect_button(child)
		_connect_buttons_recursive(child)

func _on_node_added(node: Node):
	if node is BaseButton:
		_connect_button(node)

func _on_node_removed(node: Node):
	if node is BaseButton:
		# Optional: Clean up connection to prevent memory leaks from stale signals
		if node.pressed.is_connected(_play_button_sound):
			node.pressed.disconnect(_play_button_sound)

func _connect_button(button: BaseButton):
	# Avoid duplicate connections (check if already connected)
	if not button.pressed.is_connected(_play_button_sound):
		button.pressed.connect(_play_button_sound)
		# Optional: Store a reference or flag on button for faster checks
		# button.set_meta("sound_connected", true)

func _play_button_sound():
	_play_sound(button_sound)
	button_pressed.emit()  # Optional global signal

func _play_sound(stream: AudioStream):
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "UI"
	player.process_mode = Node.PROCESS_MODE_ALWAYS  # Play even when paused
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free, CONNECT_ONE_SHOT)
