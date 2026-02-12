extends Node

signal language_changed(locale: String)

const SAVE_FILE := "user://quantum_collapse_language.save"

const LANGUAGE_FLAGS := {
	"en": "res://resources/flags/en.png",
	"es": "res://resources/flags/es.png",
	"gl": "res://resources/flags/gl.png"
}

const LANGUAGE_NAMES := {
	"en": "English",
	"es": "Español",
	"gl": "Galego"
}

var current_locale: String = "en"

func _ready():
	load_language()
	apply_language()

func change_language(locale: String):
	if locale in LANGUAGE_FLAGS:
		current_locale = locale
		apply_language()
		save_language()
		emit_signal("language_changed", locale)

func apply_language():
	TranslationServer.set_locale(current_locale)

func get_flag_path(locale: String) -> String:
	return LANGUAGE_FLAGS.get(locale, LANGUAGE_FLAGS["en"])

func get_language_name(locale: String) -> String:
	return LANGUAGE_NAMES.get(locale, "English")

func save_language():
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_var({"locale": current_locale})
		file.close()

func load_language():
	if not FileAccess.file_exists(SAVE_FILE):
		current_locale = OS.get_locale_language()
		if not current_locale in LANGUAGE_FLAGS:
			current_locale = "en"
		return
	
	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		if data is Dictionary and "locale" in data:
			if data.locale in LANGUAGE_FLAGS:
				current_locale = data.locale

func get_available_languages() -> Array:
	return LANGUAGE_FLAGS.keys()
