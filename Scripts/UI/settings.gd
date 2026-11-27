extends Control

# Ссылки на элементы UI (назначьте их в инспекторе или через @onready)
@onready var volume_slider: HSlider = $VolumeSlider
@onready var vsync_checkbox: CheckBox = $VsyncCheckBox
@onready var fullscreen_checkbox: CheckBox = $FullscreenCheckBox
@onready var sensitivity_slider: HSlider = $SensitivitySlider

func _ready():
	# При открытии меню синхронизируем ползунки с текущими настройками
	volume_slider.value = SettingsManager.master_volume
	vsync_checkbox.button_pressed = (SettingsManager.vsync_mode != DisplayServer.VSYNC_DISABLED)
	fullscreen_checkbox.button_pressed = SettingsManager.is_fullscreen
	sensitivity_slider.value = SettingsManager.mouse_sensitivity

# --- ОБРАБОТЧИКИ ИЗМЕНЕНИЙ В UI ---

func _on_volume_slider_value_changed(value: float):
	SettingsManager.master_volume = value
	SettingsManager.apply_settings() # Громкость меняется сразу, без нажатия "Применить"
	SettingsManager.save_settings()  # Сохраняем на диск

func _on_vsync_checkbox_toggled(toggled_on: bool):
	if toggled_on:
		SettingsManager.vsync_mode = DisplayServer.VSYNC_ENABLED
	else:
		SettingsManager.vsync_mode = DisplayServer.VSYNC_DISABLED
		
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_fullscreen_checkbox_toggled(toggled_on: bool):
	SettingsManager.is_fullscreen = toggled_on
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_sensitivity_slider_value_changed(value: float):
	SettingsManager.mouse_sensitivity = value
	# Здесь можно не вызывать apply_settings(), если скрипт игрока 
	# сам читает SettingsManager.mouse_sensitivity каждый кадр.
	SettingsManager.save_settings()
