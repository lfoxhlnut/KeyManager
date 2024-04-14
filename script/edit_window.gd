class_name EditWindow
extends Panel

signal confirmed(_data: Data)
## canceled will emit automatically after confirmed emit
signal canceled


const GROUP_NAME = "ew_body_le"
const EwSubInfoTscn = preload("res://ui/ew_sub_info.tscn")

## 额外效果: 如果为 EwSubInfo.TYPE.label, 那么 add 按钮会被隐藏
@export var sub_info_type := EwSubInfo.TYPE.line_edit:
	set(v):
		if not is_node_ready():
			await ready
		head.type = v
		for i: HBoxContainer in vbox.get_children():
			var sub_info: EwSubInfo = i.get_child(0)
			sub_info.type = v
		sub_info_type = v
		if v == EwSubInfo.TYPE.label:
			add.hide()
		else:
			add.show()

var data := Data.new():
	set(v):
		if not is_node_ready():
			await ready
		data.title = v.title
		data.info = v.info
		initialize()

@onready var head: EwSubInfo = $Head
@onready var body: Control = $Body
@onready var vbox: VBoxContainer = $Body/ScrollContainer/VBoxContainer
@onready var scroll_container: ScrollContainer = $Body/ScrollContainer
@onready var add: Button = $Body/Add


var info_id: int


func _ready() -> void:
	head.size.x = size.x
	head.size.y = 48
	vbox.custom_minimum_size.x = scroll_container.size.x
	#data = Data.new("title ff", ["info1", "info3", "fffff中文ffffff"])


func initialize() -> void:
	head.text = data.title
	info_id = 0
	free_vbox()
	
	for i: String in data.info:
		vbox.add_child(create_hbox(i))


func create_hbox(content: String = "") -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.custom_minimum_size.x = vbox.custom_minimum_size.x
	hbox.custom_minimum_size.y = 48
	
	var sub_info: EwSubInfo = EwSubInfoTscn.instantiate()
	sub_info.type = sub_info_type
	sub_info.add_to_group(GROUP_NAME)	# 需要保证同时只有一个 edit window 在运行才会正常
	sub_info.anchor_left = 0
	sub_info.text = content
	sub_info.id = info_id
	info_id += 1
	sub_info.custom_minimum_size.x = hbox.custom_minimum_size.x * 0.6
	
	var del := Button.new()
	del.text = "delete"
	del.pressed.connect(func():
		# BUG: 这样写比较省事, 但是如果用户一直删删加加, info_id 会爆
		for k: Node in hbox.get_children():
			k.queue_free()
		hbox.queue_free()
	)
	
	var swap := func(a: EwSubInfo, b: EwSubInfo):
		var s: String = a.text
		a.text = b.text
		b.text = s
		
	
	var move_up := Button.new()
	move_up.text = "up"
	move_up.pressed.connect(func():
		# 可以保证即使只有一个节点或者该节点是最前面的节点也不会有问题
		for i: EwSubInfo in get_lines(true):
			if i.id < sub_info.id:	# 该节点之前第一个节点
				swap.call(i, sub_info)
				break
	)
	
	var move_down := Button.new()
	move_down.text = "down"
	move_down.pressed.connect(func():
		for i: EwSubInfo in get_lines():
			if i.id > sub_info.id:	# 该节点之后第一个节点
				swap.call(i, sub_info)
				break
	)
	
	hbox.add_child(sub_info)
	hbox.add_child(del)
	hbox.add_child(move_up)
	hbox.add_child(move_down)
	return hbox


func free_vbox() -> void:
	for i: HBoxContainer in vbox.get_children():
		for k: Control in i.get_children():
			k.queue_free()
		i.queue_free()


func _exit_tree() -> void:
	free_vbox()


func _on_confirm_pressed() -> void:
	data.title = head.text
	data.info = []
	for i: EwSubInfo in get_lines():
		if i.text != "":	# 忽略无效项
			data.info.append(i.text)
	confirmed.emit(data)
	_on_cancel_pressed()


func get_lines(reverse: bool = false) -> Array[EwSubInfo]:
	var nodes: Array[Node] = get_tree().get_nodes_in_group(GROUP_NAME)
	var with_type: Array[EwSubInfo] = []
	with_type.assign(nodes)
	
	with_type.sort_custom(
		func(a: EwSubInfo, b: EwSubInfo):
			if reverse:
				return a.id > b.id
			else:
				return a.id < b.id
	)
	return with_type


func _on_add_pressed() -> void:
	vbox.add_child(create_hbox())


func _on_cancel_pressed() -> void:
	canceled.emit()
