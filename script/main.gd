extends Node
@onready var content: Content = $Content
@onready var menu: Menu = $HUD/Menu


func _on_menu_load_pressed() -> void:
	var res := Global.load_save(await menu.get_save_key(), menu.save_path)
	if res == {}:
		# TODO: 添加提示等
		print_debug("no save or password err")
	else:
		content.data_dict = res


func _on_menu_save_pressed() -> void:
	# TODO: 储存 user config
	Global.save(content.data_dict, await menu.get_save_key(), menu.save_path)


func _on_menu_add_pressed(data: Data) -> void:
	content.add_item(data)


func _on_menu_add_class_pressed(data: Data) -> void:
	content.add_class(data)

