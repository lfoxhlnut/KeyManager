class_name EwSubInfo
extends Control

# 其实如果仅是想禁用输入, 可以通过 line_edit::editable 属性来调整

enum TYPE {
	label,
	line_edit,
}
@export var type := TYPE.label:
	set(v):
		if not is_node_ready():
			await ready
		
		# 第一次调用的时候 actived 可能还没初始化
		if actived:
			actived.hide()
		match v:
			TYPE.label:
				actived = label
			TYPE.line_edit:
				actived = line_edit
			_:
				print_debug("unknown type")
		actived.show()
		type = v

var text: String:
	set(v):
		for i: Control in get_children():
			i.text = v
		text = v
		if not is_node_ready():
			await ready
		
		# 设置光标位置不会导致 line_edit 获得焦点
		# 手动操作是因为可能 text 赋值在使用 focus_input_area() 之后,
		# 这样光标位置与文本长度对不上
		line_edit.caret_column = text.length()
var id: int


@onready var label: Label = $Label
@onready var line_edit: LineEdit = $LineEdit
@onready var actived: Control


func _ready() -> void:
	for i: Control in get_children():
		i.position = Vector2.ZERO
	_on_resized()


func _on_resized() -> void:
	for i: Control in get_children():
		i.size = size


func focus_input_area() -> void:
	if actived == line_edit:
		line_edit.call_deferred("grab_focus")
