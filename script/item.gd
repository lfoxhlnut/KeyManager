class_name Item
extends Panel

signal data_modified

const PressToCopyTscn := preload("res://ui/press_to_copy.tscn")
const EditWindowTscn := preload("res://ui/edit_window.tscn")

@onready var head: HBoxContainer = $Head
@onready var title: PressToCopy = $Head/Title
@onready var unfold: TextureButton = $Head/Unfold
@onready var edit: Button = $Head/Edit
@onready var body: VBoxContainer = $Body

var data := Data.new():
	set(v):
		# NOTE:直接写 data = v 不会触发 Data.title 和 Data.info 的 setter
		data.title = v.title
		data.info = v.info
		initialize()

func _ready() -> void:
	head.custom_minimum_size.x = size.x * 0.6
	head.custom_minimum_size.y = 64
	title.custom_minimum_size = head.custom_minimum_size
	body.position.y = 64
	size.y = head.size.y


func initialize() -> void:
	if not is_node_ready():
		await ready
	title.text = data.title
	
	free_body()
	var loop := 0
	for i: String in data.info:
		var info := PressToCopyTscn.instantiate()
		info.custom_minimum_size.x = title.custom_minimum_size.x
		info.custom_minimum_size.y = 32
		info.global_position = body.global_position
		info.text = i
		info.use_color_rect = true
		loop = (loop + 1) % 2
		if loop == 1:
			info.bg_color = Color("404040")
		else:
			info.bg_color = Color("737373")
		body.add_child(info)


func free_body() -> void:
	for i in body.get_children():
		i.queue_free()


func _exit_tree() -> void:
	free_body()


func _on_unfold_toggled(toggled_on: bool) -> void:
	body.visible = toggled_on
	_on_head_or_body_resized()


# 可以考虑把 edit 功能从 item 里分离
func _on_edit_pressed() -> void:
	var ew: EditWindow = EditWindowTscn.instantiate()
	ew.data = data
	
	var center_ew := func():
		ew.global_position = 0.5 * Global.WIN_SIZE - 0.5 * ew.size
	ew.resized.connect(center_ew)
	
	# 现在这样写也行, 也可考虑用 menu(或者将来可能是 hud)的方法 get data from ew
	ew.confirmed.connect(func(_data: Data):
		data = _data
		data_modified.emit()
	)
	center_ew.call()
	Global.get_hud().add_child(ew)
	Global.get_hud().exclusive_mouse = true
	
	await ew.canceled
	ew.queue_free()
	Global.get_hud().exclusive_mouse = false


func _on_head_or_body_resized() -> void:
	if not is_node_ready():
		await ready
	# 这里只能用 custom_minimum_size 而非 size, 因为要放在容器里
	# 再者, 用 size 的话, 如果写 custom_minimum_size.y = size.y, 那就二者不会再变小
	if body.visible:
		custom_minimum_size.x = maxf(head.size.x, body.size.x)	# 这样的写法也导致 custom_min_size 不会变小, 但是目前没问题就不改了
		
		# head 和 body 之间可能有空隙, 不能直接用 head.size.y + body.size.y
		# BUG: 然而似乎视觉上还是有些小错误, 再说吧
		custom_minimum_size.y = (body.position.y - head.position.y) + body.size.y
	else:
		custom_minimum_size.y = head.size.y
	
