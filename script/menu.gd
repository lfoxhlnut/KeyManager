class_name Menu
extends Control
# 这个菜单功能太少了, 很简单, 就不用官方组件了吧

@onready var hbox: HBoxContainer = $HBoxContainer
@onready var save: Button = $HBoxContainer/Save
@onready var load_btn: Button = $HBoxContainer/Load
@onready var add_class: Button = $HBoxContainer/AddClass
@onready var add: Button = $HBoxContainer/Add
@onready var edit_save_path: Button = $HBoxContainer/EditSavePath
@onready var info_input: InfoInput = $InfoInput
@onready var file_dialog: FileDialog = $FileDialog

var save_key: String
var save_path: String = Global.DEFAULT_SAVE_PATH

func _ready() -> void:
	hbox.size = size
	for i: Control in hbox.get_children():
		i.custom_minimum_size.x = 128
	
	file_dialog.size.x = 0.75 * size.x
	file_dialog.size.y = 0.4 * size.x	# 这里用的是 size.x, 只能保证 menu 的宽度和屏幕一样
	file_dialog.position = 0.5 * (Global.WIN_SIZE - (file_dialog.size as Vector2))	# 居中
	


func _on_edit_save_path_pressed() -> void:
	#info_input.placeholder_text = "Input new save path here(Leave blink as default: %s)" % [ProjectSettings.globalize_path(Global.DEFAULT_SAVE_PATH)]
	file_dialog.current_dir = ProjectSettings.globalize_path(save_path)
	file_dialog.show()
	var s: String = await file_dialog.dir_selected
	if not s.is_empty():
		save_path = s
	print_debug("save path selected: ", save_path)
	file_dialog.hide()


