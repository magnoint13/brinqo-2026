@tool
extends EditorScript

var csv_content = """keys,en,es,gl
MENU_START,Start,Iniciar,Iniciar
MENU_LEVEL_SELECT,Level select,Seleccionar nivel,Seleccionar nivel
MENU_SETTINGS,Settings,Configuración,Configuración
MENU_QUIT,Quit,Salir,Saír
PAUSE_TITLE,PAUSED,PAUSA,PAUSA
PAUSE_RESUME,Resume,Continuar,Continuar
PAUSE_RESTART,Restart Level,Reiniciar nivel,Reiniciar nivel
PAUSE_LEVEL_SELECT,Level Select,Seleccionar nivel,Seleccionar nivel
PAUSE_SETTINGS,Settings,Configuración,Configuración
PAUSE_MAIN_MENU,Main Menu,Menú principal,Menú principal
SETTINGS_TITLE,Settings,Configuración,Configuración
SETTINGS_MASTER,Master,General,Xeral
SETTINGS_MUSIC,Music,Música,Música
SETTINGS_SFX,SFX,Efectos,Efectos
SETTINGS_BACK,Back,Volver,Volver
LEVEL_SELECT_TITLE,Select Level,Seleccionar nivel,Seleccionar nivel
LEVEL_BUTTON_PREFIX,Level,Nivel,Nivel
BACK,Back,Volver,Volver
HUD_MENU,Menu,Menú,Menú
HUD_ROTATE,Rotate,Rotar,Rotar
HUD_COLLAPSE,Force Collapse,Colapso forzado,Colapso forzado
GAME_VICTORY,VICTORY!,¡VICTORIA!,¡VITORIA!
GAME_OVER,GAME OVER,JUEGO TERMINADO,XOGO REMATADO
GAME_COLLAPSING,COLLAPSING...,COLAPSANDO...,COLAPSANDO...
GAME_TIMER_FORMAT,Coherence time: %.1fs,Tiempo de coherencia: %.1fs,Tempo de coherencia: %.1fs
GAME_DEATH_REDZONE,COLLAPSED IN DANGER ZONE! GAME OVER!,¡COLAPSADO EN ZONA PELIGROSA! ¡JUEGO TERMINADO!,¡COLAPSADO EN ZONA PERIGOSA! ¡XOGO REMATADO!
GAME_HINT_COVERAGE,You must cover all green areas,Debes cubrir todas las áreas verdes,Debes cubrir todas as áreas verdes
GAME_NEUTRAL_SURVIVED,The system survived!,¡El sistema sobrevivió!,¡O sistema sobreviveu!
GAME_WIN_STABILIZED,QUANTUM STATE STABILIZED! YOU WIN!,¡ESTADO CUÁNTICO ESTABILIZADO! ¡GANASTE!,¡ESTADO CUÁNTICO ESTABILIZADO! ¡GANACHE!
LEVEL_INSTRUCTION_01,Collapse on the green zone,Colapsa en la zona verde,Colapsa na zona verde
LEVEL_INSTRUCTION_02,Don't collapse on the red zone!,¡No colapses en la zona roja!,¡Non colapses na zona vermella!
LEVEL_INSTRUCTION_03,Repeatedly collapse against walls to slip through,Colapsa repetidamente contra las paredes para pasar,Colapsa repetidamente contra as paredes para pasar
LEVEL_INSTRUCTION_04,Collapse one particle in each zone,Colapsa una partícula en cada zona,Colapsa unha partícula en cada zona
LEVEL_INSTRUCTION_05,Hold R and use WASD to position and rotate,Mantén R y usa WASD para posicionar y rotar,Mantén R e usa WASD para posicionar e rotar
TUNNEL_EFFECT,Tunnel Effect,Efecto túnel,Efeito túnel
ENTANGLE_BREAK,Entanglement broke!,Entrelazamiento roto!,Entrelazamento quebrado!
RE_ENTANGLEMENT,RE-ENTANGLEMENT!,ENTRELAZAMIENTO!,ENTRELAZAMENTO!
"""

func _run():
	var lines = csv_content.split("\n")
	var headers = lines[0].split(",")
	
	var translations = {
		"en": [],
		"es": [],
		"gl": []
	}
	
	# Parse CSV
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line.is_empty():
			continue
		var parts = line.split(",")
		var key = parts[0]
		
		for lang_idx in range(1, parts.size()):
			var locale_code = headers[lang_idx]
			var translation = parts[lang_idx]
			translations[locale_code].append([key, translation])
	
	# Create translation files
	for locale in translations.keys():
		var translation_data = {
			"keys": [],
			"strings": []
		}
		
		for item in translations[locale]:
			translation_data["keys"].append(item[0])
			translation_data["strings"].append(item[1])
		
		# Create Godot translation file
		var content = '[gd_resource type="Translation" format=3]\n\n[resource]\n'
		content += 'keys=PackedStringArray(' + str(translation_data["keys"]) + ')\n'
		content += 'strings=PackedStringArray(' + str(translation_data["strings"]) + ')\n'
		
		var file_path = "res://resources/translations/translations." + locale + ".translation"
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			file.store_string(content)
			file.close()
			print("Created translation file: " + file_path)
