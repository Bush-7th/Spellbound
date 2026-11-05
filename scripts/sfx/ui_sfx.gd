class_name UISfx
extends Node

static var sfx_data: SfxData = preload("res://assets/sfx/ui_sfx_data.tres")

static var playback: AudioStreamPlaybackPolyphonic

static func play_sfx(sfx_name: StringName) -> void:
	if not sfx_data:
		push_error("UISfx: Не назначен SfxData ресурс!")
		return
	var stream: AudioStream = sfx_data.sfx_dict.get(sfx_name)
	if stream != null:
		playback.play_stream(stream)
	else:
		push_warning("UISfx: Звук с именем '" + sfx_name + "' не найден.")
