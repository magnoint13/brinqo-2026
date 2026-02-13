extends Node

const TOTAL_LEVELS: int = 10

var current_level: int = 1
var unlocked_levels: Array[int] = [1]

signal level_completed(level_number: int)
signal level_unlocked(level_number: int)

func _ready():
	load_progress()

func start_level(level_number: int):
	if level_number < 1 or level_number > TOTAL_LEVELS:
		push_error("Invalid level number: " + str(level_number))
		return
	
	current_level = level_number
	var level_path = "res://levels/Level%02d.tscn" % level_number
	get_tree().change_scene_to_file(level_path)

func complete_current_level():
	mark_level_complete()
	
	var next_level = current_level + 1
	if next_level <= TOTAL_LEVELS:
		show_level_complete_screen()
	else:
		show_game_complete_screen()

func mark_level_complete():
	level_completed.emit(current_level)
	
	var next_level = current_level + 1
	if next_level <= TOTAL_LEVELS and not next_level in unlocked_levels:
		unlocked_levels.append(next_level)
		level_unlocked.emit(next_level)
		save_progress()

func show_level_complete_screen():
	# This is now handled by the WinPopup in the game scene
	pass

func show_game_complete_screen():
	# This is now handled by the WinPopup in the game scene
	pass

func restart_current_level():
	start_level(current_level)

func go_to_main_menu():
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")

func go_to_level_select():
	get_tree().change_scene_to_file("res://ui/LevelSelect.tscn")

func is_level_unlocked(level_number: int) -> bool:
	return level_number in unlocked_levels

func save_progress():
	var save_data = {
		"unlocked_levels": unlocked_levels
	}
	var save_file = FileAccess.open("user://quantum_collapse_save.save", FileAccess.WRITE)
	if save_file:
		save_file.store_var(save_data)
		save_file.close()

func load_progress():
	if not FileAccess.file_exists("user://quantum_collapse_save.save"):
		return
	
	var save_file = FileAccess.open("user://quantum_collapse_save.save", FileAccess.READ)
	if save_file:
		var save_data = save_file.get_var()
		save_file.close()
		
		if save_data.has("unlocked_levels"):
			unlocked_levels = save_data["unlocked_levels"]
			if not 1 in unlocked_levels:
				unlocked_levels.append(1)
