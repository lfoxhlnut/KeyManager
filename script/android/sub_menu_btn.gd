@tool
extends Control

@onready var save_operation: HBoxContainer = $SaveOperation
@onready var item_operation: HBoxContainer = $ItemOperation
@onready var class_operation: HBoxContainer = $ClassOperation

func _ready() -> void:
	for i: HBoxContainer in get_children():
		i.position = Vector2.ZERO
		i.set_deferred("size", size)
		#i.size = size


func hide_children() -> void:
	# Callable expected by all() should return a bool value,
	# otherwise the callable will be called only once.
	get_children().all(func(i: Control):
		i.hide()
		return true
	)

func _on_save_op_pressed() -> void:
	hide_children()
	save_operation.show()


func _on_item_op_pressed() -> void:
	hide_children()
	item_operation.show()


func _on_class_op_pressed() -> void:
	hide_children()
	class_operation.show()
