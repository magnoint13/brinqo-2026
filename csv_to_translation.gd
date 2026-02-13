@tool
extends EditorScript

const TRANSLATIONS_CSV = "res://resources/translations/translations.csv"
const OUTPUT_DIR = "res://resources/translations/"

func _run():
	var file = FileAccess.open(TRANSLATIONS_CSV, FileAccess.READ)
	if not file:
		push_error('ERROR: translations CSV not found: %s' % TRANSLATIONS_CSV)
		return
	
	var csv_content = file.get_as_text()
	file.close()
	
	var lines = csv_content.split("\n")
	if lines.size() < 2:
		push_error('ERROR: CSV has no data')
		return
	
	# Init locales from header
	var headers = lines[0].strip_edges().split(",")
	var translations = {}
	for i in range(1, headers.size()):
		translations[headers[i]] = []
	
	# Parse CSV
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line.is_empty():
			continue
		
		var parts = line.split(",", false)
		if parts.size() < 2:
			print('WARN: line %d with only %d parts. Ignoring line...' % [i, parts.size()])
			continue
		
		var key = parts[0]
		
		for lang_idx in range(1, parts.size()):
			var locale_code = headers[lang_idx]
			var translation = parts[lang_idx]
			translations[locale_code].append([key, translation])
	
	# Create translation files
	for locale in translations.keys():
		var translation_res = Translation.new()
		translation_res.locale = locale
		
		for pair in translations[locale]:
			translation_res.add_message(pair[0], pair[1])
		
		var output_path = OUTPUT_DIR + 'translations.%s.translation' % locale
		var err = ResourceSaver.save(translation_res, output_path)
		if err != OK:
			push_error('Failed saving translation: %s (error %d)' % [output_path, err])
		else:
			print('Created translation file: %s' % output_path)
