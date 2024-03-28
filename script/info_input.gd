class_name InfoInput
extends Panel

signal confirmed(text: String)
@onready var hbox: HBoxContainer = $HBoxContainer
@onready var line_edit: LineEdit = $HBoxContainer/LineEdit

# TODO: 提示词和背景色放到检查器里

func _on_confirm_pressed() -> void:
	print_debug("line edit text is ", line_edit.text)
	confirmed.emit(line_edit.text)


func _on_h_box_container_resized() -> void:
	size = hbox.size * 1.2
	hbox.position = 0.1 * hbox.size
