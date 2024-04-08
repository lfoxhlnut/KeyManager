class_name Content
extends Control

const ItemTscn := preload("res://ui/item.tscn")
@export var min_title_text_size: int = 12	# 官方没有提供 tab min width 这样的功能, 出此下策

var data_dict: Dictionary = {}:
	set(v):
		data_dict = v.duplicate()
		initialize()
@onready var title: TabBar = $Title
@onready var center_container: CenterContainer = $CenterContainer
@onready var scroll_container: ScrollContainer = $CenterContainer/ScrollContainer
@onready var v_box: VBoxContainer = $CenterContainer/ScrollContainer/VBoxContainer



func _ready() -> void:
	data_dict = {
		"class1": [
			Data.new("title1", ["fff", "11中文"]),
			Data.new("222", []),
			Data.new("3", ["password", "11中文"]),
		],
		"kirov reporting": [
			Data.new("vehicle", ["fff", "11中文"]),
			Data.new("222", ["password", "11中文"]),
			Data.new("3", ["password", "11中文"]),
		],
	}
	_on_title_resized()


func _exit_tree() -> void:
	free_vbox_children()


func initialize() -> void:
	title.clear_tabs()
	for key: String in data_dict:
		add_title_tab(key)
	
	_on_title_tab_changed(title.current_tab)


func add_title_tab(s: String) -> void:
	## 优先使用此函数替代 title.add_tab()
	if s.length() >= min_title_text_size:
		title.add_tab(s)
		return
	@warning_ignore("integer_division")
	var left := (min_title_text_size - s.length()) / 2
	var right := min_title_text_size - left - s.length()
	var res := " ".repeat(left) + s + " ".repeat(right)
	title.add_tab(res)
	

func _on_title_resized() -> void:
	if not is_node_ready():
		await ready
	center_container.position.y = title.position.y + title.size.y + 16
	center_container.size.x = size.x
	center_container.size.y = size.y - center_container.position.y
	scroll_container.custom_minimum_size.y = center_container.size.y * 0.9


func _on_title_tab_changed(tab: int = title.current_tab) -> void:
	free_vbox_children()
	var key: String = get_title_tab_text(tab)
	for id: int in data_dict[key].size():
		var item: Item = ItemTscn.instantiate()
		# NOTE: gdscript 里没有函数闭包, 不能访问函数的局部变量
		# 但是 局部节点变量的 queue_free() 是有用的, 全局变量或说类的成员也是可以访问的
		item.data_modified.connect(func():
			data_dict[key][id] = item.data
		)
		item.data = data_dict[key][id]
		v_box.add_child(item)
		
		# NOTE: 必须主动展开一次, item 的 size, min_size 才是正确的
		item._on_unfold_toggled(true)
		item._on_unfold_toggled(false)
		scroll_container.custom_minimum_size.x = item.custom_minimum_size.x


func get_title_tab_text(tab: int) -> String:
	## 优先使用此函数替代 title.get_tab_title()
	var res := title.get_tab_title(tab).strip_edges()
	return res


func free_vbox_children() -> void:
	for i: Node in v_box.get_children():
		i.queue_free()


func add_item(data: Data) -> void:
	var key := get_title_tab_text(title.current_tab)
	(data_dict[key] as Array).append(data)
	_on_title_tab_changed(title.current_tab)


func add_class(data: Data) -> void:
	if not data_dict.has(data.title):
		title.add_tab(data.title)
		data_dict[data.title] = []
	for i: String in data.info:
		(data_dict[data.title] as Array).append(Data.new(i))
	
	initialize()	# 只设置 data_dict 的一个键, 会触发 setter 吗


func modify_current_class(modified: Data) -> void:
	var key := get_title_tab_text(title.current_tab)
	var items: Array[Data] = []
	
	if modified.title != key and data_dict.has(modified.title):
		# 当前 class 新的名字与原有的重复
		# TODO: 警告用户
		items = data_dict[modified.title]	# 无需深复制
	
	# 筛选出保留下的那些 item
	for i: String in modified.info:
		for k: Data in data_dict[key]:
			if k.title == i:
				items.append(k)
				break
	
	data_dict.erase(key)
	data_dict[modified.title] = items
	initialize()
	
	# 切换 tab 到刚刚修改过的 class
	var tab_id := get_tab_id_by_text(modified.title)
	assert(tab_id != -1)
	title.current_tab = tab_id	# 会触发_on_title_tab_changed


func get_current_class_info() -> Data:
	var key := get_title_tab_text(title.current_tab)
	var info: Array[String] = []
	for i: Data in data_dict[key]:
		info.append(i.title)
	return Data.new(key, info)


func get_tab_id_by_text(s: String) -> int:
	for i: int in title.tab_count:
		if get_title_tab_text(i) == s:
			return i
	return -1

