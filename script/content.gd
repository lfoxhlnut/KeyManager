class_name Content
extends Control

const ItemTscn := preload("res://ui/item.tscn")
const EditWindowTscn = preload("res://ui/edit_window.tscn")
const InfoInputTscn = preload("res://ui/info_input.tscn")
@export var min_title_text_size: int = 12	# 官方没有提供 tab min width 这样的功能, 出此下策

var data_dict: Dictionary = {}:
	set(v):
		data_dict = v.duplicate()
		initialize()
@onready var title: TabBar = $Title
@onready var v_box: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var scroll_container: ScrollContainer = $ScrollContainer


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
	scroll_container.size.y = 0.6 * size.y


func _exit_tree() -> void:
	free_vbox_children()


func initialize() -> void:
	title.clear_tabs()
	for key: String in data_dict:
		add_title_tab_text(key)
	
	_on_title_tab_changed(title.current_tab)



func add_title_tab_text(s: String) -> void:
	"""优先使用此函数替代 title.add_tab()"""
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
	scroll_container.position.y = title.size.y + 64 + 32


func _on_title_tab_changed(tab: int = title.current_tab) -> void:
	free_vbox_children()
	var key: String = get_title_tab_text(tab)
	for id: int in data_dict[key].size():
		var item: Item = ItemTscn.instantiate()
		v_box.add_child(item)
		item.resized.connect(func():
			# 我也不记得这里为什么要这样写了,
			# 只知道删掉这句话或者删掉 0.5*size.x 显示就有问题
			# 虽然我已经设置 scroll container 锚点什么的居中了
			scroll_container.position.x = 0.5 * size.x - 0.5 * item.size.x
		)
		item.minimum_size_changed.connect(func():
			scroll_container.size.x = item.custom_minimum_size.x
		)
		# NOTE: gdscript 里没有函数闭包, 不能访问函数的局部变量
		# 但是 局部节点变量的 queue_free() 是有用的, 全局变量或说类的成员也是可以访问的
		item.data_modified.connect(func():
			data_dict[key][id] = item.data
		)
		item.data = data_dict[key][id]
		
		# ↓ 这两句注释的背景是, vbox 的父节点直接是 content 而非 scroll 容器, 不过现在问题仍然存在
		# 真奇怪, 无论怎么设置 vbox 的 pos 都没用, remote 检查器里的数据和
		# print 打印出来的数据不一样, 必须手动点击一下展开, vbox 的位置才是正确的
		item._on_unfold_toggled(true)
		item._on_unfold_toggled(false)


func get_title_tab_text(tab: int) -> String:
	"""优先使用此函数替代 title.get_tab_title()"""
	var res := title.get_tab_title(tab).strip_edges()
	return res


func free_vbox_children() -> void:
	for i: Node in v_box.get_children():
		i.queue_free()


func add_item(data: Data) -> void:
	var key := title.get_tab_title(title.current_tab)
	(data_dict[key] as Array).append(data)
	_on_title_tab_changed(title.current_tab)


func add_class(data: Data) -> void:
	if not data_dict.has(data.title):
		title.add_tab(data.title)
		data_dict[data.title] = []
	for i: String in data.info:
		(data_dict[data.title] as Array).append(Data.new(i))
	
	initialize()	# 只设置 data_dict 的一个键, 会触发 setter 吗
