class_name Content
extends Control

const ItemTscn := preload("res://ui/item.tscn")
@export var min_title_text_size: int = 12	# 官方没有提供 tab min width 这样的功能, 出此下策


var tab_title: Array[String] = []
var tab_info: Array[Array] = []
# 学到的: 这里封装 current_... 使得下次修改存档版本会变得简单得多
var current_tab_title: String = "":
	set(v):
		tab_title[title.current_tab] = v
	get:
		return tab_title[title.current_tab]
var current_tab_info: Array[Data] = []:
	set(v):
		tab_info[title.current_tab] = v
	get:
		# 这里不需要借助 modify_arr_with_data() 是因为 set_save_data() 在添加的时候用的临时数组 t 声明了 Array[Data]
		return tab_info[title.current_tab]

@onready var title: TabBar = $Title
@onready var center_container: CenterContainer = $CenterContainer
@onready var scroll_container: ScrollContainer = $CenterContainer/ScrollContainer
@onready var v_box: VBoxContainer = $CenterContainer/ScrollContainer/VBoxContainer



func _ready() -> void:
	_on_title_resized()


func _exit_tree() -> void:
	free_vbox_children()


func initialize() -> void:
	title.clear_tabs()
	for key: String in tab_title:
		add_title_tab(key)
	
	_on_title_tab_changed(title.current_tab)


func set_save_data(d: Dictionary, ver: String) -> void:
	# 学到的: 对于这种简单的数据结构, 自己手写转换就行了, 在支持不完善的框架里尝试一劳永逸地解决这个问题会非常困难甚至不可能
	match ver:
		"0.0":
			"""
d like this
d = {
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
var encoded := JSON.stringify(data_dict)
var decoded: Dictionary = JSON.parse_string(encoded)
print(decoded)
print(typeof(decoded["class1"]))		# Array
print(decoded["class1"][0] is String)	# true
			"""
			# convert to 1.0
			for key: String in d:
				tab_title.append(key)
				var data_arr: Array[Data] = []
				
				# 如果当时存档的时候, 某一个数组只有一个 str 成员, 那么 JSON.stringfy() 会把它转换成单个 str 而非 [str]
				if d[key] is String:
					d[key] = [d[key]]
				
				# Array[str] -> Array[Data]
				for i: String in d[key]:
					data_arr.append(Data.from_string(i))
				tab_info.append(data_arr)
			
		"1.0":
			"""
d = {
	tab_title=[
		"class1",
		"class2",
	],
	tab_info=[
		[Data.new(),Data.new(),Data.new(),],
		[Data.new(),Data.new(),Data.new(),],
	]
}
			"""
			tab_title = []
			tab_info = []
			for i: String in d["tab_title"]:
				tab_title.append(i)
			for i: Array in d["tab_info"]:
				var t: Array[Data] = []
				for k: String in i:
					t.append(Data.from_string(k))
				tab_info.append(t)
		_:
			print_debug("unknown save version")
	
	initialize()


func get_save_data() -> Dictionary:
	return {
		tab_title=tab_title,
		tab_info=tab_info,
	}


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


func _on_title_tab_changed(_tab: int = title.current_tab) -> void:
	free_vbox_children()
	for id: int in current_tab_info.size():
		var item: Item = ItemTscn.instantiate()
		# NOTE: gdscript 里没有函数闭包, 不能访问函数的局部变量
		# 但是 局部节点变量的 queue_free() 是有用的, 全局变量或说类的成员也是可以访问的
		item.data_modified.connect(func():	# 单个 item 的数据修改不是 content.gd 管的, 不过这没问题, TODO: 也许应该把 content.gd 简化一下, 部分功能下放到子节点的脚本
			current_tab_info[id] = item.data
		)
		item.data = current_tab_info[id]
		v_box.add_child(item)
		
		# NOTE: 必须主动展开一次, item 的 size, min_size 才是正确的
		item._on_unfold_toggled(true)
		item._on_unfold_toggled(false)
		scroll_container.custom_minimum_size.x = item.custom_minimum_size.x


func free_vbox_children() -> void:
	for i: Node in v_box.get_children():
		i.queue_free()


func add_item(data: Data) -> void:
	current_tab_info.append(data)
	# append 不会触发 setter
	_on_title_tab_changed(title.current_tab)


func add_class(data: Data) -> void:
	if not tab_title.has(data.title):
		title.add_tab(data.title)
		tab_info.append([])
	for i: String in data.info:
		tab_info[-1].append(Data.new(i))
	

func modify_current_class(modified: Data) -> void:
	var res: Array[Data] = []
	
	# 判断当前 class 修改后是否与其他的 class 冲突
	if modified.title != current_tab_title and tab_title.has(modified.title):
		# TODO: 警告用户
		# 默认和原有的 class 合并
		var id := tab_title.find(modified.title)
		res = tab_info[id]	# 无需深复制
	
	# 筛选出保留下的那些 item
	for i: String in modified.info:
		for k: Data in current_tab_info:
			if k.title == i:
				res.append(k)
				break
	
	current_tab_title = modified.title
	current_tab_info = res
	_on_title_tab_changed()


## 返回的 Data 中, title 是当前 class 的 title, info 的各项是当前 class 所有 item 的 title
## 用于修改当前 class(修改 class 的名字, 重排 item 的顺序)
func get_current_class_info() -> Data:
	var info: Array[String] = []
	for i: Data in current_tab_info:
		info.append(i.title)
	return Data.new(current_tab_title, info)


static func modify_arr_with_data(arr: Array) -> Array[Data]:
	# 行, 为了类型安全, 可以接受这样的写法
	# 不明白为什么强制转换都不允许 Array -> Array[Data], 转换出错那就在转换报错呗
	var t: Array[Data] = []
	for i: Data in arr:
		t.append(i)
	return t
