class_name InfoInput
extends Panel

signal confirmed(text: String)

@export var placeholder_text := "input info here":
	set(v):
		placeholder_text = v
		if not is_node_ready():
			await ready
		line_edit.placeholder_text = v


@onready var hbox: HBoxContainer = $HBoxContainer
@onready var line_edit: LineEdit = $HBoxContainer/LineEdit

# TODO: 背景色放到检查器里

func _on_confirm_pressed() -> void:
	print_debug("line edit text is ", line_edit.text)
	confirmed.emit(line_edit.text)


func _on_h_box_container_resized() -> void:
	size = hbox.size * 1.2
	hbox.position = 0.1 * hbox.size
