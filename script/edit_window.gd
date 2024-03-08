extends Panel

var data := Data.new():
	set(v):
		if not is_node_ready():
			await ready
		data.title = v.title
		data.info = v.info
		initialize()
		
@onready var head: LineEdit = $Head
@onready var body: Control = $Body
@onready var vbox: VBoxContainer = $Body/VBoxContainer
@onready var add: Button = $Body/Add


func _ready() -> void:
	head.size.x = size.x
	head.size.y = 64
	vbox.custom_minimum_size.x = size.x
	body.position.y = 64 + 16
	data = Data.new("title ff", ["info1", "info3"])


func initialize() -> void:
	vbox.custom_minimum_size.y = 64 * data.info.size()
	body.size.x = vbox.custom_minimum_size.x
	body.size.y = vbox.custom_minimum_size.y + 128
	head.text = data.title
	free_vbox()
	for id: int in data.info.size():
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.custom_minimum_size.x = vbox.custom_minimum_size.x
		hbox.custom_minimum_size.y = 48
		
		var line_edit := LineEdit.new()
		line_edit.anchor_left = 0
		line_edit.text = data.info[id]
		line_edit.custom_minimum_size.x = vbox.custom_minimum_size.x * 0.6
		line_edit.size.y = 48
		
		var btn := Button.new()
		btn.anchor_right = 0
		btn.text = "delete"
		btn.size.x = vbox.size.x * 0.3
		btn.pressed.connect(func():
			# 不知道行不行, 理论上 lambda 函数不依赖于节点
			for k: Node in hbox.get_children():
				k.queue_free()
			hbox.queue_free()
			print_debug("hbox freed")
			)
		
		hbox.add_child(line_edit)
		hbox.add_child(btn)
		vbox.add_child(hbox)


func free_vbox() -> void:
	for i: HBoxContainer in vbox.get_children():
		for k: Node in i.get_children():
			k.queue_free()
		i.queue_free()


func _exit_tree() -> void:
	free_vbox()
