extends Node

@onready var music_player: AudioStreamPlayer

var scene_music = {
	"MainMenu": "res://resources/music/menu_music.mp3",
	"LevelSelect": "res://resources/music/menu_music.mp3",
}

var current_music: String = ""
var paused_position: float = 0.0

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	get_tree().node_added.connect(_on_scene_changed)
	
	_check_current_scene()

func _on_scene_changed(node):
	if node is Control or node is Node2D:
		await get_tree().process_frame
		_check_current_scene()

func _check_current_scene():
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
	
	var scene_name = current_scene.name
	play_scene_music(scene_name)

func play_scene_music(scene_name: String):
	var music_path = scene_music.get(scene_name, "")
	
	if music_path == "":
		stop_music()
		return
	
	if music_path == current_music and music_player.playing:
		return
	
	var stream = load(music_path)
	if stream:
		music_player.stream = stream
		music_player.play()
		current_music = music_path

func stop_music():
	music_player.stop()
	current_music = ""

func pause_music():
	if music_player.playing:
		paused_position = music_player.get_playback_position()
		music_player.stop()

func resume_music():
	if current_music != "" and not music_player.playing:
		music_player.play(paused_position)

func _notification(what):
	if what == NOTIFICATION_PAUSED:
		pause_music()
	elif what == NOTIFICATION_UNPAUSED:
		resume_music()
