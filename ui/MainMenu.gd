extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var level_select_button = $VBoxContainer/LevelsButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var title_sprite = $Sprite2D
@onready var settings_menu = $SettingsMenu
@onready var language_button = $LanguageButton
@onready var flag_popup = $FlagPopup
@onready var english_button = $FlagPopup/LanguageContainer/English
@onready var galician_button = $FlagPopup/LanguageContainer/Galician
@onready var spanish_button = $FlagPopup/LanguageContainer/Spanish

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	language_button.pressed.connect(_on_language_button_pressed)
	english_button.pressed.connect(_on_english_selected)
	galician_button.pressed.connect(_on_galician_selected)
	spanish_button.pressed.connect(_on_spanish_selected)
	
	_update_language_button_flag()
	flag_popup.visible = false
	
	if title_sprite:
		var original_y = title_sprite.position.y
		var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(title_sprite, "position:y", original_y - 15.0, 1.5)
		tween.tween_property(title_sprite, "position:y", original_y, 1.5)

func _on_start_pressed():
	GameManager.start_level(1)

func _on_level_select_pressed():
	GameManager.go_to_level_select()

func _on_quit_pressed():
	get_tree().quit()

func _on_settings_pressed():
	settings_menu.open("main_menu")

func _on_language_button_pressed():
	flag_popup.visible = !flag_popup.visible

func _on_english_selected():
	LanguageManager.change_language("en")
	flag_popup.visible = false
	_update_language_button_flag()

func _on_galician_selected():
	LanguageManager.change_language("gl")
	flag_popup.visible = false
	_update_language_button_flag()

func _on_spanish_selected():
	LanguageManager.change_language("es")
	flag_popup.visible = false
	_update_language_button_flag()

func _update_language_button_flag():
	var flag_texture = load(LanguageManager.get_flag_path(LanguageManager.current_locale))
	language_button.texture_normal = flag_texture
