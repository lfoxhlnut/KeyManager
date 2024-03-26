extends Control

const ItemTscn := preload("res://ui/item.tscn")

var data_dict: Dictionary = {}:
	set(v):
		data_dict = v.duplicate()
		initialize()

@onready var title: TabBar = $Title
# TODO: 添加滚动条
@onready var v_box: VBoxContainer = $VBoxContainer


func _ready() -> void:
	data_dict = {
		"class1": [
			Data.new("title1", ["fff", "11中文"]),
			Data.new("222", ["password", "11中文"]),
			Data.new("3", ["password", "11中文"]),
		],
		"kirov reporting": [
			Data.new("vehicle", ["fff", "11中文"]),
			Data.new("222", ["password", "11中文"]),
			Data.new("3", ["password", "11中文"]),
		],
	}
	v_box.position.x = 0.5 * size.x
	
	pass


func _exit_tree() -> void:
	free_vbox_children()


func initialize() -> void:
	title.clear_tabs()
	for key: String in data_dict:
		title.add_tab(key)
	_on_title_tab_changed(title.current_tab)


func _on_title_resized() -> void:
	if not is_node_ready():
		await ready
	v_box.position.y = title.size.y + 64


func _on_title_tab_changed(tab: int) -> void:
	free_vbox_children()
	var key: String = title.get_tab_title(title.current_tab)
	for id: int in data_dict[key].size():
		var item: Item = ItemTscn.instantiate()
		v_box.add_child(item)
		item.resized.connect(func():
			v_box.position.x = 0.5 * size.x - 0.5 * item.size.x
		)
		item.data_modified.connect(func():
			data_dict[key][id] = item.data
		)
		item.data = data_dict[key][id]
		# 真奇怪, 无论怎么设置 vbox 的 pos 都没用, remote 检查器里的数据和
		# print 打印出来的数据不一样, 必须手动点击一下展开, vbox 的位置才是正确的
		item._on_unfold_toggled(true)
		item._on_unfold_toggled(false)
	


func free_vbox_children() -> void:
	for i: Node in v_box.get_children():
		i.queue_free()


func _on_save_pressed() -> void:
	print_debug("ready to save:", data_dict)
	Global.save(data_dict)


func _on_reload_pressed() -> void:
	data_dict = Global.load_save()
