@tool
class_name AutoRun
extends Node

# Prevent callback function runs too many times.
# It seems that scene with tool script could not use "@onready var timer"
# (at least there will be an error "Cannot call method 'is_stopped' on a null value.").
var interval := 2
var can_callback := true

func _ready() -> void:
	ProjectSettings.settings_changed.connect(_on_project_settings_changed)


func _on_project_settings_changed() -> void:
	if not can_callback:
		return
	can_callback = false
	get_tree().create_timer(interval).timeout.connect(func():
		can_callback = true
	)
	
	adjust_width_override()


func adjust_width_override() -> void:
	var height_override: int = ProjectSettings.get_setting("display/window/size/window_height_override")
	var height: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	var width: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var width_override := int(1.0 * height_override * width / height)
	ProjectSettings.set_setting(
		"display/window/size/window_width_override",
		width_override
	)
