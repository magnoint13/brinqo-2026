extends Control

@onready var master_slider: HSlider = $CenterContainer/VBoxContainer/MasterVolume/Slider
@onready var master_value: Label = $CenterContainer/VBoxContainer/MasterVolume/ValueLabel
@onready var music_slider: HSlider = $CenterContainer/VBoxContainer/MusicVolume/Slider
@onready var music_value: Label = $CenterContainer/VBoxContainer/MusicVolume/ValueLabel
@onready var sfx_slider: HSlider = $CenterContainer/VBoxContainer/SFXVolume/Slider
@onready var sfx_value: Label = $CenterContainer/VBoxContainer/SFXVolume/ValueLabel

var _previous_scene: String = ""
var _is_paused: bool = false

func _ready():
	_load_settings()

func open(previous_scene: String = "", is_paused: bool = false):
	_previous_scene = previous_scene
	_is_paused = is_paused
	_load_settings()
	visible = true

func close(previous_scene: String = "", is_paused: bool = false):
	_previous_scene = previous_scene
	_is_paused = is_paused
	visible = false

func _load_settings():
	master_slider.value = SettingsManager.get_master_volume()
	music_slider.value = SettingsManager.get_music_volume()
	sfx_slider.value = SettingsManager.get_sfx_volume()
	_update_value_labels()

func _update_value_labels():
	master_value.text = str(int(master_slider.value * 100)) + "%"
	music_value.text = str(int(music_slider.value * 100)) + "%"
	sfx_value.text = str(int(sfx_slider.value * 100)) + "%"

func _on_master_slider_value_changed(value: float):
	SettingsManager.set_master_volume(value)
	_update_value_labels()

func _on_music_slider_value_changed(value: float):
	SettingsManager.set_music_volume(value)
	_update_value_labels()

func _on_sfx_slider_value_changed(value: float):
	SettingsManager.set_sfx_volume(value)
	_update_value_labels()

func _on_back_button_pressed():
	visible = false
	if _is_paused:
		return
	elif _previous_scene == "main_menu":
		return
	else:
		return
