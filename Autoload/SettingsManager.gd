extends Node

# --- Пути к файлам ---
const SETTINGS_PATH = "user://settings.json"
const CONTROLS_PATH = "user://controls.json"

# --- Настройки игры ---
var master_volume: float = 1.0
var vsync_mode: int = DisplayServer.VSYNC_ENABLED
var fullscreen_mode: bool = false
var current_language: String = "ru"

# --- Управление (Keybinds) ---
var key_look_up: int = KEY_W
var key_look_down: int = KEY_S
var key_move_left: int = KEY_A
var key_move_right: int = KEY_D
var key_jump: int = KEY_SPACE
var key_dash: int = KEY_SHIFT
var key_dodge: int = KEY_CTRL


func _ready():
	load_settings()
	load_controls()
	apply_settings()

# ==========================================
# ЛОГИКА ДЛЯ SETTINGS.JSON
# ==========================================

func save_settings():
	var settings = {
		"Volume": master_volume,
		"VSync": vsync_mode,
		"Fullscreen": fullscreen_mode,
		"Language": current_language
	}
	
	var json_string = JSON.stringify(settings, "\t")
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	
	if file == null:
		push_error("Не удалось открыть " + SETTINGS_PATH)
		return
	file.store_string(json_string)
	file.close()


func load_settings():
	if not FileAccess.file_exists(SETTINGS_PATH):
		print("Файл settings.json не найден. Используются настройки по умолчанию.")
		return
		
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		push_error("Не удалось открыть " + SETTINGS_PATH)
		return
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Ошибка парсинга JSON: " + json.get_error_message())
		return
	
	var node_data = json.data	
	if node_data is Dictionary:
		master_volume = node_data.get("Volume", 1.0)
		vsync_mode = node_data.get("VSync", DisplayServer.VSYNC_ENABLED)  # ИСПРАВЛЕНО: было "Vsync"
		fullscreen_mode = node_data.get("Fullscreen", false)
		current_language = node_data.get("Language", "ru")


func apply_settings():
	DisplayServer.window_set_vsync_mode(vsync_mode)
	
	if fullscreen_mode:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
	
	TranslationServer.set_locale(current_language)


# ==========================================
# ЛОГИКА ДЛЯ CONTROLS.JSON
# ==========================================

func save_controls():
	var controls = {
		"look_up": key_look_up,
		"look_down": key_look_down,
		"move_left": key_move_left,
		"move_right": key_move_right,
		"jump": key_jump,
		"dash": key_dash,
		"dodge": key_dodge
	}
	
	var json_string = JSON.stringify(controls, "\t")
	var file = FileAccess.open(CONTROLS_PATH, FileAccess.WRITE)
	
	if file == null:
		push_error("Не удалось открыть " + CONTROLS_PATH)
		return
	file.store_string(json_string)
	file.close()


func load_controls():
	if not FileAccess.file_exists(CONTROLS_PATH):
		print("Файл controls.json не найден. Используются стандартные клавиши.")
		return
		
	var file = FileAccess.open(CONTROLS_PATH, FileAccess.READ)
	if file == null:
		push_error("Не удалось открыть " + CONTROLS_PATH)
		return
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Ошибка парсинга controls.json: " + json.get_error_message())
		return
	
	var controls_data = json.data	
	if controls_data is Dictionary:
		key_look_up = controls_data.get("look_up", KEY_W)
		key_look_down = controls_data.get("look_down", KEY_S)
		key_move_left = controls_data.get("move_left", KEY_A)
		key_move_right = controls_data.get("move_right", KEY_D)
		key_jump = controls_data.get("jump", KEY_SPACE)
		key_dash = controls_data.get("dash", KEY_SHIFT)
		key_dodge = controls_data.get("dodge", KEY_CTRL)

# Вспомогательная функция для UI
func get_key_name(key_code: int) -> String:
	return OS.get_keycode_string(key_code)
