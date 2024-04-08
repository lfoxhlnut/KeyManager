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


# 不要主动使用这个变量
var _res: Data = Data.new()
# 可以考虑做成 HUD 的方法
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
func get_input(placeholder: String = "") -> Array:
	info_input.text = ""
	info_input.placeholder_text = placeholder
	center_container.show()
	hud.exclusive_mouse = true
	
	# 此处写法过于丑陋, 原因在于下面的把 infoinput.txt 设置成空, 还不想设置全局变量 save_key
	# 可考虑: 发送 confirm 的时候发送 cancel, 给 confirm 绑定回调方法, await cancel
	# 现在能跑就不再改了
	var res: Array = await info_input.closed
	center_container.hide()
	hud.exclusive_mouse = false
	info_input.text = ""
	return res


func _on_save_operation_index_pressed(index: int) -> void:
	match index:
		SaveOp.SAVE, SaveOp.LOAD:
			var res := await get_input("Input secret key here")
			if not res[0] == info_input.canceled:
				var save_key: String = res[1]["text"]
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
