class_name EditWindow
extends Panel

signal confirmed(_data: Data)
## canceled will emit automatically after confirmed emit
signal canceled


const GROUP_NAME := "ew_body_le"

var data := Data.new():
	set(v):
		if not is_node_ready():
			await ready
		data.title = v.title
		data.info = v.info
		initialize()

@onready var head: LineEdit = $Head
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
	
	var line_edit := MyLineEdit.new()
	line_edit.add_to_group(GROUP_NAME)	# 需要保证同时只有一个 edit window 在运行才会正常
	line_edit.anchor_left = 0
	line_edit.text = content
	line_edit.id = info_id
	info_id += 1
	line_edit.custom_minimum_size.x = hbox.custom_minimum_size.x * 0.6
	
	var del := Button.new()
	del.text = "delete"
	del.pressed.connect(func():
		# BUG: 这样写比较省事, 但是如果用户一直删删加加, info_id 会爆
		for k: Node in hbox.get_children():
			k.queue_free()
		hbox.queue_free()
	)
	
	var swap := func(a: MyLineEdit, b: MyLineEdit):
		var s: String = a.text
		a.text = b.text
		b.text = s
		
	
	var move_up := Button.new()
	move_up.text = "up"
	move_up.pressed.connect(func():
		# 可以保证即使只有一个节点或者该节点是最前面的节点也不会有问题
		for i: MyLineEdit in get_lines(true):
			if i.id < line_edit.id:	# 该节点之前第一个节点
				swap.call(i, line_edit)
				break
	)
	
	var move_down := Button.new()
	move_down.text = "down"
	move_down.pressed.connect(func():
		for i: MyLineEdit in get_lines():
			if i.id > line_edit.id:	# 该节点之后第一个节点
				swap.call(i, line_edit)
				break
	)
	
	hbox.add_child(line_edit)
	hbox.add_child(del)
	hbox.add_child(move_up)
	hbox.add_child(move_down)
	return hbox


func free_vbox() -> void:
	for i: HBoxContainer in vbox.get_children():
		for k: Node in i.get_children():
			k.queue_free()
		i.queue_free()


func _exit_tree() -> void:
	free_vbox()


func _on_confirm_pressed() -> void:
	data.title = head.text
	data.info = []
	for i: MyLineEdit in get_lines():
		if i.text != "":	# 忽略无效项
			data.info.append(i.text)
	confirmed.emit(data)
	canceled.emit()


func get_lines(reverse: bool = false) -> Array[MyLineEdit]:
	var nodes: Array[Node] = get_tree().get_nodes_in_group(GROUP_NAME)
	var with_type: Array[MyLineEdit] = []
	for i: Node in nodes:
		with_type.append(i as MyLineEdit)
	with_type.sort_custom(
		func(a: MyLineEdit, b: MyLineEdit):
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
