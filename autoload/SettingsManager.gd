extends Node

const SAVE_FILE := "user://quantum_collapse_settings.save"

const MASTER_BUS := 0
const MUSIC_BUS := 1
const SFX_BUS := 2
const UI_BUS := 3

var _settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 1.0,
	"sfx_volume": 1.0
}

func _ready():
	load_settings()
	_apply_settings()

func set_master_volume(value: float):
	_settings.master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(MASTER_BUS, _linear_to_db(_settings.master_volume))
	save_settings()

func set_music_volume(value: float):
	_settings.music_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(MUSIC_BUS, _linear_to_db(_settings.music_volume))
	save_settings()

func set_sfx_volume(value: float):
	_settings.sfx_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(SFX_BUS, _linear_to_db(_settings.sfx_volume))
	save_settings()

func get_master_volume() -> float:
	return _settings.master_volume

func get_music_volume() -> float:
	return _settings.music_volume

func get_sfx_volume() -> float:
	return _settings.sfx_volume

func save_settings():
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_var(_settings)
		file.close()

func load_settings():
	if not FileAccess.file_exists(SAVE_FILE):
		return
	
	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var loaded_data = file.get_var()
		file.close()
		if loaded_data is Dictionary:
			_settings.merge(loaded_data, true)

func _apply_settings():
	AudioServer.set_bus_volume_db(MASTER_BUS, _linear_to_db(_settings.master_volume))
	AudioServer.set_bus_volume_db(MUSIC_BUS, _linear_to_db(_settings.music_volume))
	AudioServer.set_bus_volume_db(SFX_BUS, _linear_to_db(_settings.sfx_volume))

func _linear_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return 20.0 * log(value) / log(10.0)
