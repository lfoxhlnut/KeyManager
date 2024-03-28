extends Control

const ItemTscn := preload("res://ui/item.tscn")
const EditWindowTscn = preload("res://ui/edit_window.tscn")
const InfoInputTscn = preload("res://ui/info_input.tscn")

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
			#Data.new("222", ["password", "11中文"]),
			Data.new("222", []),
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
	#print_debug("ready to save:", data_dict)
	Global.save(data_dict, await get_save_key())


var _save_key: String
func get_save_key() -> String:
	var info_input: InfoInput = InfoInputTscn.instantiate()
	# TODO: hud 遮罩不能设为无色透明, 不然 info input 太不明显
	info_input.global_position = Vector2(300, 400)
	
	# NOTE: gdscript 里没有函数闭包, 不能访问函数的局部变量
	# 但是 info_input.queue_free() 这句是有用的
	info_input.confirmed.connect(func(text: String):
		_save_key = text
		info_input.queue_free()
		Global.get_hud().exclusive_mouse = false
	)
	Global.get_hud().add_child(info_input)
	Global.get_hud().exclusive_mouse = true
	await info_input.confirmed
	return _save_key


func _on_reload_pressed() -> void:
	var res := Global.load_save(await get_save_key())
	if res == {}:
		# TODO: 添加提示等
		print_debug("no save or password err")
	else:
		data_dict = res


# _on_add_pressed 和 _on_add_class_pressed 都源自 item.gd 中一个函数,
# 可考虑封装, 就像 get_save_key 一样, 用 await
func _on_add_pressed() -> void:
	var ew: EditWindow = EditWindowTscn.instantiate()
	
	ew.resized.connect(func():
		ew.global_position = 0.5 * Global.WIN_SIZE - 0.5 * ew.size
	)
	
	ew.confirmed.connect(func(_data: Data):
		var key := title.get_tab_title(title.current_tab)
		(data_dict[key] as Array).append(_data)
		_on_title_tab_changed(title.current_tab)
		
		ew.queue_free()
		Global.get_hud().exclusive_mouse = false
	)
	Global.get_hud().add_child(ew)
	Global.get_hud().exclusive_mouse = true


func _on_add_class_pressed() -> void:
	var ew: EditWindow = EditWindowTscn.instantiate()
	
	ew.resized.connect(func():
		ew.global_position = 0.5 * Global.WIN_SIZE - 0.5 * ew.size
	)
	
	ew.confirmed.connect(func(_data: Data):
		if not data_dict.has(_data.title):
			title.add_tab(_data.title)
			data_dict[_data.title] = []
		for i: String in _data.info:
			(data_dict[_data.title] as Array).append(Data.new(i))
		
		initialize()	# 只设置 data_dict 的一个键, 会触发 setter 吗
		
		ew.queue_free()
		Global.get_hud().exclusive_mouse = false
	)
	Global.get_hud().add_child(ew)
	Global.get_hud().exclusive_mouse = true
