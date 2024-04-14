class_name EwSubInfo
extends Control

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
