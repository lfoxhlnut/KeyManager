extends Node
@onready var content: Content = $Content
@onready var menu: Menu = $HUD/Menu

# TODO: del class
# 添加注释, 或者两者一起(可能比较
# auto save
# 属性: 不显示
# save structure
# edit window 也需要滚动条
# menu.infoinput 位置有问题, 当内容特别多的时候, 此时删东西也有问题

func _ready() -> void:
	_on_menu_load_pressed("111")	# 会覆盖掉 content.gd 里的测试数据


func _on_menu_load_pressed(save_key: String = await menu.get_save_key()) -> void:
	var res := Global.load_save(save_key, menu.save_path)
	if res == {}:
		# TODO: 添加提示等
		print_debug("no save or password err")
	else:
		content.data_dict = res


func _on_menu_save_pressed(save_key: String = await menu.get_save_key()) -> void:
	Global.save_data(content.data_dict, save_key, menu.save_path)


func _on_menu_item_add_pressed(data: Data) -> void:
	if not data.is_empty():
		content.add_item(data)


func _on_menu_class_add_pressed(data: Data) -> void:
	if not data.is_empty():
		content.add_class(data)



func _on_menu_item_manage_pressed() -> void:
	var old_data := content.get_current_class_info()
	var modified := await menu.get_data_from_ew(old_data)
	content.modify_current_class(modified)
