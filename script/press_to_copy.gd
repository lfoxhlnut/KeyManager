class_name PressToCopy
extends TextureButton

var text: String:
	set(v):
		if not is_node_ready():
			await ready
		label.text = v
		text = v


@export_color_no_alpha var bg_color := Color("000000"):
	set(v):
		if not is_node_ready():
			await ready
		color_rect.color = v
		bg_color = v
@export var use_color_rect := false:
	set(v):
		if not is_node_ready():
			await ready
		color_rect.visible = v
		use_color_rect = v

@onready var label: Label = $Label
@onready var color_rect: ColorRect = $ColorRect


func  _ready() -> void:
	bg_color = bg_color
	_on_minimum_size_changed()


func _on_pressed() -> void:
	DisplayServer.clipboard_set(text)


func _on_minimum_size_changed() -> void:
	color_rect.custom_minimum_size = custom_minimum_size
	label.custom_minimum_size = custom_minimum_size
