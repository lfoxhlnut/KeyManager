class_name Content
extends Control

const ItemTscn := preload("res://ui/item.tscn")
const EditWindowTscn = preload("res://ui/edit_window.tscn")
const InfoInputTscn = preload("res://ui/info_input.tscn")

var data_dict: Dictionary = {}:
	set(v):
		data_dict = v.duplicate()
		initialize()
@onready var menu: Menu = Global.get_hud().get_node("Menu")	# TODO: 由于把 menu 分离开了, 需要设置信号以通信, 暂先这样写着
@onready var title: TabBar = $Title
# TODO: 添加滚动条 # 似乎官方组件有考虑到这一点
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


func _on_title_tab_changed(_tab: int) -> void:
	free_vbox_children()
	var key: String = title.get_tab_title(title.current_tab)
	for id: int in data_dict[key].size():
		var item: Item = ItemTscn.instantiate()
		v_box.add_child(item)
		item.resized.connect(func():
			v_box.position.x = 0.5 * size.x - 0.5 * item.size.x
		)
		# NOTE: gdscript 里没有函数闭包, 不能访问函数的局部变量
		# 但是 局部节点变量的 queue_free() 是有用的, 全局变量或说类的成员也是可以访问的
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
