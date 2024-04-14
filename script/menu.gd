class_name Menu
extends Control

signal save_pressed(save_key: String)
signal load_pressed(save_key: String)
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
@onready var save_operation: PopupMenu = $"MenuBar/Save Operation"
@onready var item_operation: PopupMenu = $"MenuBar/Item Operation"
@onready var class_operation: PopupMenu = $"MenuBar/Class Operation"
@onready var info_input: InfoInput = $CenterContainer/InfoInput
@onready var file_dialog: FileDialog = $FileDialog
@onready var hud: HUD = $".."
@onready var center_container: CenterContainer = $CenterContainer

var save_path: String = Global.DEFAULT_SAVE_PATH
var save_ver := ""


func _ready() -> void:
	center_container.size = Global.WIN_SIZE
	info_input.custom_minimum_size = Global.WIN_SIZE * 0.6
	info_input.input_size = Vector2(size.x * 0.4, size.x * 0.1)
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
	var config := Global.config
	if not config.has_section(CONFIG_SECTION_NAME):
		return
	
	# 有默认值的话不需要判定键值是否存在
	save_path = config.get_value(CONFIG_SECTION_NAME, "save_path", Global.DEFAULT_SAVE_PATH)
	save_ver = config.get_value(CONFIG_SECTION_NAME, "save_ver", "0.0")


func _exit_tree() -> void:
	save_config()


func save_config() -> void:
	Global.config.set_value(CONFIG_SECTION_NAME, "save_path", save_path)
	Global.config.set_value(CONFIG_SECTION_NAME, "save_ver", save_ver)


func _on_edit_save_path_pressed() -> void:
	file_dialog.current_dir = ProjectSettings.globalize_path(save_path)
	file_dialog.show()
	var s: String = await file_dialog.dir_selected
	if not s.is_empty():
		save_path = s
	print_debug("save path selected: ", save_path)
	file_dialog.hide()


var _res: Data = Data.new()
# 可以考虑做成 HUD 的方法, ew 的定位可以用 center container
## 如果返回的 Data 的 valid 是无效的, 那么不保证 Data 的其他信息是有用的(也不保证是空的)
func get_data_from_ew(default: Data = Data.new()) -> Data:
	var ew: EditWindow = EditWindowTscn.instantiate()
	ew.data = default
	ew.global_position = 0.5 * Global.WIN_SIZE - 0.5 * ew.size	# 这句话产生正确效果是因为 ew 的锚点在左上角
	
	hud.add_child(ew)
	hud.exclusive_mouse = true
	
	_res.valid = false
	ew.confirmed.connect(func(d: Data):
		_res = d
	)
	await ew.canceled
	ew.queue_free()
	hud.exclusive_mouse = false
	return _res


# 可以考虑做成 HUD 的方法
var _input: String = ""
var _valid := false
func get_input(placeholder: String = "") -> Dictionary:
	info_input.text = ""
	info_input.placeholder_text = placeholder
	center_container.show()
	hud.exclusive_mouse = true
	
	_input = ""
	_valid = false
	info_input.confirmed.connect(func(input: String):
		_input = input
		_valid = true
	, CONNECT_ONE_SHOT
	)
	await info_input.canceled
	center_container.hide()
	hud.exclusive_mouse = false
	info_input.text = ""
	return {
		valid=_valid,
		input=_input,
	}


func _on_save_operation_index_pressed(index: int) -> void:
	match index:
		SaveOp.SAVE, SaveOp.LOAD:
			var res := await get_input("Input secret key here")
			if res.valid:
				var save_key: String = res.input
				if index == SaveOp.SAVE:
					save_pressed.emit(save_key)
				else:
					load_pressed.emit(save_key)
		SaveOp.EDIT_PATH:
			_on_edit_save_path_pressed()
		SaveOp.OPEN_PATH:
			# NOTE: ↓ 未在 android 上实现, 不行就试试 shell_open()
			OS.shell_show_in_file_manager(ProjectSettings.globalize_path(save_path), true)
		_:
			print_debug("unexpected index: ", index)


func _on_item_operation_index_pressed(index: int) -> void:
	match index:
		ItemOp.ADD:
			var d := await get_data_from_ew()
			if d.valid:
				item_add_pressed.emit(d)
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
