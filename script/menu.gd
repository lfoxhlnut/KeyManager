class_name Menu
extends MenuBar

signal save_pressed
signal load_pressed
signal item_add_pressed(data: Data)
signal item_manage_pressed
signal class_add_pressed(data: Data)
signal class_manage_pressed

const EditWindowTscn = preload("res://ui/edit_window.tscn")
const CONFIG_SECTION_NAME = "menu"
enum SaveOp {
	SAVE, LOAD, EDIT_PATH, OPEN_PATH
}
const SaveOpText = [
	"Save",
	"Load",
	"Edit save path",
	"Open save path",
]
enum  ItemOp { ADD, MANAGE }
const ItemOpText = [
	"Add item",
	"Manage items",
]
enum  ClassOp { ADD, MANAGE }
const ClassOpText = [
	"Add class",
	"Manage classes"
]
@onready var save_operation: PopupMenu = $"Save Operation"
@onready var item_operation: PopupMenu = $"Item Operation"
@onready var class_operation: PopupMenu = $"Class Operation"

@onready var info_input: InfoInput = $InfoInput
@onready var file_dialog: FileDialog = $FileDialog
@onready var hud: HUD = $".."

var save_path: String = Global.DEFAULT_SAVE_PATH


func _ready() -> void:
	@warning_ignore("narrowing_conversion")
	file_dialog.size.x = 0.75 * size.x
	@warning_ignore("narrowing_conversion")
	file_dialog.size.y = 0.4 * size.x	# 这里用的是 size.x, 只能保证 menu 的宽度和屏幕一样
	file_dialog.position = 0.5 * (Global.WIN_SIZE - (file_dialog.size as Vector2))	# 居中
	
	set_popup_menu_item_text()
	load_config()


func set_popup_menu_item_text() -> void:
	for i: String in SaveOpText:
		save_operation.add_item(i)
	for i: String in ItemOpText:
		item_operation.add_item(i)
	for i: String in ClassOpText:
		class_operation.add_item(i)


func load_config() -> void:
	if not Global.config.has_section(CONFIG_SECTION_NAME):
		return
	
	save_path = Global.config.get_value(CONFIG_SECTION_NAME, "save_path", Global.DEFAULT_SAVE_PATH)


func _exit_tree() -> void:
	save_config()


func save_config() -> void:
	Global.config.set_value(CONFIG_SECTION_NAME, "save_path", save_path)


func _on_edit_save_path_pressed() -> void:
	file_dialog.current_dir = ProjectSettings.globalize_path(save_path)
	file_dialog.show()
	var s: String = await file_dialog.dir_selected
	if not s.is_empty():
		save_path = s
	print_debug("save path selected: ", save_path)
	file_dialog.hide()


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
	hud.exclusive_mouse = true
	
	var save_key: String = await info_input.confirmed
	info_input.hide()
	# TODO: 重置 info input 的输入信息
	hud.exclusive_mouse = false
	return save_key


func _on_save_operation_index_pressed(index: int) -> void:
	match index:
		SaveOp.SAVE:
			save_pressed.emit()
		SaveOp.LOAD:
			load_pressed.emit()
		SaveOp.EDIT_PATH:
			_on_edit_save_path_pressed()
		SaveOp.OPEN_PATH:
			print_debug("OPEN_PATH")
		_:
			print_debug("unexpected index: ", index)


func _on_item_operation_index_pressed(index: int) -> void:
	match index:
		ItemOp.ADD:
			item_add_pressed.emit(await get_data_from_ew())
		ItemOp.MANAGE:
			item_manage_pressed.emit()
		_:
			print_debug("unexpected index: ", index)


func _on_class_operation_index_pressed(index: int) -> void:
	match index:
		ClassOp.ADD:
			class_add_pressed.emit(await get_data_from_ew())
		ClassOp.MANAGE:
			class_manage_pressed.emit()
		_:
			print_debug("unexpected index: ", index)
