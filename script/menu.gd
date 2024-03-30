class_name Menu
extends Control
# 这个菜单功能太少了, 很简单, 就不用官方组件了吧

signal save_pressed
signal load_pressed
signal add_class_pressed(data: Data)
signal add_pressed(data: Data)

const EditWindowTscn = preload("res://ui/edit_window.tscn")

@onready var hbox: HBoxContainer = $HBoxContainer
@onready var save: Button = $HBoxContainer/Save
@onready var load_btn: Button = $HBoxContainer/Load
@onready var add_class: Button = $HBoxContainer/AddClass
@onready var add: Button = $HBoxContainer/Add
@onready var edit_save_path: Button = $HBoxContainer/EditSavePath
@onready var info_input: InfoInput = $InfoInput
@onready var file_dialog: FileDialog = $FileDialog
@onready var hud: HUD = $".."

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


func _on_save_pressed() -> void:
	save_pressed.emit()


func _on_load_pressed() -> void:
	load_pressed.emit()


func _on_add_class_pressed() -> void:
	add_class_pressed.emit(await get_data_from_ew())


func _on_add_pressed() -> void:
	add_pressed.emit(await get_data_from_ew())


func get_data_from_ew() -> Data:
	var ew: EditWindow = EditWindowTscn.instantiate()
	
	ew.resized.connect(func():
		ew.global_position = 0.5 * Global.WIN_SIZE - 0.5 * ew.size
	)
	
	hud.add_child(ew)
	hud.exclusive_mouse = true
	
	var res: Data = await ew.confirmed
	ew.queue_free()
	hud.exclusive_mouse = false
	return res


func get_save_key() -> String:
	# TODO: hud 遮罩不能设为无色透明, 不然 info input 太不明显
	info_input.placeholder_text = "Input secret key here"
	info_input.show()
	hud.add_child(info_input)
	hud.exclusive_mouse = true
	
	var save_key: String = await info_input.confirmed
	info_input.hide()
	hud.exclusive_mouse = false
	return save_key
