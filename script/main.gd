extends Node
@onready var content: Content = $Content
@onready var menu: Menu = $HUD/Menu

# TODO:
# 添加注释, 或者两者一起(可能比较
# auto save
# 属性: 不显示
# item 文本过长如何处理
# ew 换序的时候保持视觉正确的控件焦点

func _ready() -> void:
	_on_menu_load_pressed("111")	# for test


func _on_menu_load_pressed(save_key: String) -> void:
	var res := Global.load_save(save_key, menu.save_path)
	if res == {}:
		# TODO: 添加提示等
		print_debug("no save or password err")
		return
	
	print_debug(menu.save_ver)
	match menu.save_ver:
		"0.0":
			content.set_save_data(res, menu.save_ver)
		"1.0":
			content.set_save_data(res["content"], menu.save_ver)
		"1.1":
			res = Global.deserialize_dict(res)
			content.set_save_data(res["content"], menu.save_ver)
		_:
			print_debug("unknown version")


func _on_menu_save_pressed(save_key: String) -> void:
	menu.save_ver = "1.1"
	var to_save := Global.serialize_dict(get_save_dict())
	Global.save_data(to_save, save_key, menu.save_path)


func get_save_dict() -> Dictionary:
	var save_dict := {
		content=content.get_save_data(),
	}
	return save_dict


func _on_menu_item_add_pressed(data: Data) -> void:
	# 空的数据不被承认
	if not data.is_empty():
		content.add_item(data)


func _on_menu_class_add_pressed(data: Data) -> void:
	if not data.is_empty():
		content.add_class(data)


func _on_menu_item_manage_pressed() -> void:
	var old_data := content.get_current_class_info()
	var modified := await menu.get_data_from_ew(old_data)
	
	# 用户按的不是 Cancel 才承认这次操作. 也可考虑把获取 modified 的工作放给 item_manage 这个信号, 就像 save, load 一样
	if modified.valid:
		content.modify_current_class(modified)


func _on_menu_class_manage_pressed() -> void:
	var original := Data.new("", content.tab_title)
	
	var modified := await menu.get_data_from_ew(original, EwSubInfo.TYPE.label)
	if not modified.valid:
		return
	
	var res := modified.info
	var sequence: Array[int] = []
	for i: String in res:
		for id: int in content.tab_title.size():
			if i == content.tab_title[id]:
				sequence.append(id)
				break
	
	content.rearrange_classes_sequence(sequence)
	
		
