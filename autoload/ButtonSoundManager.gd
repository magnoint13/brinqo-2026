extends Node

@export var button_down_path: String = "res://resources/sfx/sfx_onbuttonpressed.wav"
@export var button_up_path: String = "res://resources/sfx/sfx_onbuttonreleased.wav"

var sound_down: AudioStream
var sound_up: AudioStream

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Cargar ambos sonidos
	sound_down = load(button_down_path)
	sound_up = load(button_up_path)
	
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_connect_existing_buttons")
	
func _connect_existing_buttons():
	_connect_buttons_recursive(get_tree().root)

func _connect_buttons_recursive(parent: Node):
	for child in parent.get_children():
		if child is BaseButton:
			_connect_button(child)
		_connect_buttons_recursive(child)

func _on_node_added(node: Node):
	if node is BaseButton:
		_connect_button(node)

func _connect_button(button: BaseButton):
	# Conexión para cuando se PRESIONA (hacia abajo)
	if not button.button_down.is_connected(_play_down_sound):
		button.button_down.connect(_play_down_sound)
	
	# Conexión para cuando se SUELTA (hacia arriba)
	if not button.button_up.is_connected(_play_up_sound):
		button.button_up.connect(_play_up_sound)

# Funciones de reproducción
func _play_down_sound():
	_play_sound(sound_down)

func _play_up_sound():
	_play_sound(sound_up)

func _play_sound(stream: AudioStream):
	if not stream: return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "UI"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
