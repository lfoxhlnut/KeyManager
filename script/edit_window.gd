class_name EditWindow
extends Panel

signal confirmed(_data: Data)
## canceled will emit automatically after confirmed emit
signal canceled

# NOTE: 已不记得是否有必要用 group 了, 似乎这里 group 的用法有潜在的问题, 重构时要注意
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

## 如果为 true, 那么 ew 在被创建的时候会自动聚焦焦点至 title 的输入框
## 且按下 add 按钮后会自动聚焦到新创建的输入框
@export var auto_grab_focus := true
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
	
	if auto_grab_focus:
		title_grab_focus()


func initialize() -> void:
	head.text = data.title
	info_id = 0
	free_vbox()
	
	for i: String in data.info:
		vbox.add_child(create_hbox(i))
	
	if auto_grab_focus:
		title_grab_focus()


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
				
				# Index "2" relies on how hbox adds children.
				var i_up := i.get_parent().get_child(2) as Button
				i_up.grab_focus()
				break
	)
	
	var move_down := Button.new()
	move_down.text = "down"
	move_down.pressed.connect(func():
		for i: EwSubInfo in get_lines():
			if i.id > sub_info.id:	# 该节点之后第一个节点
				swap.call(i, sub_info)
				
				# Index "3" relies on how hbox adds children.
				var i_down := i.get_parent().get_child(3) as Button
				i_down.grab_focus()
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
	if auto_grab_focus:
		info_grab_focus(-1)


func _on_cancel_pressed() -> void:
	canceled.emit()


## Set focus to input area of info.
## The info will be accessed from lase one if the index is negative.
## Nothing happens if the index is out of bound.
func info_grab_focus(id: int) -> void:
	# vbox 没有子节点的情况包含在内
	if id >= vbox.get_child_count() or id < -vbox.get_child_count():
		return
	if id == -1:
		head.focus_input_area()
	else:
		var hbox: HBoxContainer = vbox.get_child(id)
		var sub_info: EwSubInfo = hbox.get_child(0)
		sub_info.focus_input_area()


## Set focus to input area of title
func title_grab_focus() -> void:
	head.focus_input_area()
