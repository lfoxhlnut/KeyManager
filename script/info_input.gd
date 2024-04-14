class_name InfoInput
extends PanelContainer

signal confirmed(text: String)
signal canceled
signal closed(_signal: Signal, param: Dictionary)

@export var placeholder_text := "input info here":
	set(v):
		placeholder_text = v
		if not is_node_ready():
			await ready
		line_edit.placeholder_text = v
@export var text := "":
	set(v):
		text = v
		if not is_node_ready():
			await ready
		line_edit.text = v
	get:
		if not is_node_ready():
			await ready
		text = line_edit.text
		return text
@export var bg_color: Color:
	set(v):
		if not is_node_ready():
			await ready
		bg_color = v
		sytle_box_flat.bg_color = v
@export var input_size: Vector2:
	set(v):
		if not is_node_ready():
			await ready
		input_size = v
		line_edit.custom_minimum_size = v


@onready var center_container: CenterContainer = $CenterContainer
@onready var hbox: HBoxContainer = $CenterContainer/HBoxContainer
@onready var line_edit: LineEdit = $CenterContainer/HBoxContainer/LineEdit
@onready var sytle_box_flat: StyleBoxFlat = StyleBoxFlat.new()


func _ready() -> void:
	add_theme_stylebox_override("panel", sytle_box_flat)


func _on_confirm_pressed() -> void:
	confirmed.emit(line_edit.text)
	_on_cancel_pressed()


func _on_resized() -> void:
	if not is_node_ready():
		await ready
	center_container.size = size


func _on_cancel_pressed() -> void:
	canceled.emit()
