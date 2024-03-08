class_name Item
extends Panel

const press_to_copy := preload("res://ui/press_to_copy.tscn")

@onready var head: HBoxContainer = $Head
@onready var title: PressToCopy = $Head/Title
@onready var unfold: TextureButton = $Head/Unfold
@onready var edit: Button = $Head/Edit
@onready var body: VBoxContainer = $Body

var data := Data.new():
	set(v):
		# NOTE:直接写 data = v 不会触发 setter
		data.title = v.title
		data.info = v.info
		initialize()

func _ready() -> void:
	head.custom_minimum_size.x = custom_minimum_size.x
	head.custom_minimum_size.y = 64
	title.custom_minimum_size = head.custom_minimum_size
	body.position.y = 64


func initialize() -> void:
	title.text = data.title
	
	free_body()
	var loop := 0
	for i: String in data.info:
		var info := press_to_copy.instantiate()
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


func _on_edit_pressed() -> void:
	pass # Replace with function body.
