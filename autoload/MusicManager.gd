extends Node

@onready var music_player: AudioStreamPlayer

# Format: "scene_name": [music_path, volume_in_db]
var scene_music = {
	"MainMenu":   ["res://resources/music/menu_music.mp3",   0],
	"LevelSelect": ["res://resources/music/menu_music.mp3",   0],
	"Level01":    ["res://resources/music/01.mp3",           0],
	"Level02":    ["res://resources/music/02.mp3",            0],
	"Level03":    ["res://resources/music/03.mp3",           -12.0],
	"Level04":    ["res://resources/music/04.mp3",            0],
	"Level05":    ["res://resources/music/05.mp3",           0],
}

var current_music: String = ""
var current_volume: float = 0.0          # in dB
var paused_position: float = 0.0

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Music"           # ← optional but recommended
	
	get_tree().node_added.connect(_on_scene_changed)
	_check_current_scene()


func _on_scene_changed(node: Node) -> void:
	# Small delay helps when the new scene isn't yet current_scene
	if node is Control or node is Node2D:
		await get_tree().process_frame
		_check_current_scene()


func _check_current_scene() -> void:
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
	var scene_name = current_scene.name
	play_scene_music(scene_name)


func play_scene_music(scene_name: String) -> void:
	var data = scene_music.get(scene_name)
	
	# No music defined for this scene → stop
	if data == null or data.size() < 1:
		stop_music()
		return
		
	var music_path: String = data[0]
	var target_volume: float = data[1] if data.size() >= 2 else 0.0
	
	# Same song already playing at correct volume → do nothing
	if music_path == current_music and music_player.playing and is_equal_approx(music_player.volume_db, target_volume):
		return
	
	var stream = load(music_path) as AudioStream
	if not stream:
		printerr("Failed to load music: ", music_path)
		return
	
	music_player.stream = stream
	music_player.volume_db = target_volume
	music_player.play()
	
	current_music = music_path
	current_volume = target_volume


func stop_music() -> void:
	music_player.stop()
	current_music = ""
	current_volume = 0.0


func pause_music() -> void:
	if music_player.playing:
		paused_position = music_player.get_playback_position()
		music_player.stop()


func resume_music() -> void:
	if current_music != "" and not music_player.playing:
		music_player.volume_db = current_volume
		music_player.play(paused_position)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			pause_music()
		NOTIFICATION_UNPAUSED:
			resume_music()
