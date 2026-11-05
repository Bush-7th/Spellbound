extends Node

var pause_menu_instance: CanvasLayer = null
var is_settings_open: bool = false
const ALLOWED_PAUSE_SCENES = ["Game"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func toggle_pause():
	var current_scene_name = get_tree().current_scene.name
	if not ALLOWED_PAUSE_SCENES.has(current_scene_name):
		return
	
	if get_tree().paused:
		close_pause_menu()
	else:
		open_pause_menu()

func open_pause_menu():
	get_tree().paused = true
	
	if pause_menu_instance == null or not is_instance_valid(pause_menu_instance):
		pause_menu_instance = preload("res://scenes/UI/pause_menu.tscn").instantiate()
		pause_menu_instance.name = "ActivePauseMenu"
		
		# 🔥 ФИКС: Используем правильные свойства для Godot 4
		# Отключаем следование за вьюпортом (камерой)
		pause_menu_instance.follow_viewport_enabled = false
		
		get_tree().root.add_child(pause_menu_instance)
	
	pause_menu_instance.visible = true
	is_settings_open = false

func close_pause_menu():
	get_tree().paused = false
	
	if pause_menu_instance != null and is_instance_valid(pause_menu_instance):
		pause_menu_instance.queue_free()
		
	pause_menu_instance = null
	is_settings_open = false

func open_settings_over_pause():
	if pause_menu_instance != null and is_instance_valid(pause_menu_instance):
		pause_menu_instance.visible = false
		
	var settings = preload("res://scenes/UI/settings_overlay.tscn").instantiate()
	settings.name = "SettingsOverlay"
	
	if "is_over_pause" in settings:
		settings.is_over_pause = true
		
	get_tree().root.add_child(settings)
	is_settings_open = true
	
	settings.tree_exited.connect(_on_settings_closed)

func _on_settings_closed():
	is_settings_open = false
	if pause_menu_instance != null and is_instance_valid(pause_menu_instance):
		pause_menu_instance.visible = true
		get_tree().paused = true
	else:
		open_pause_menu()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		var current_scene_name = get_tree().current_scene.name
		
		if not ALLOWED_PAUSE_SCENES.has(current_scene_name):
			return
			
		if is_settings_open:
			var settings_node = get_tree().root.get_node_or_null("SettingsOverlay")
			if settings_node:
				settings_node.queue_free()
		else:
			toggle_pause()
			
		get_viewport().set_input_as_handled()
