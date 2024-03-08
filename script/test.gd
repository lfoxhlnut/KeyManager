extends Control
@onready var item_2: Item = $VBoxContainer/Item2
@onready var item: Item = $VBoxContainer/Item

var data_array: Array[Data] = [
	Data.new(
		"title 1",
		["password123"],
	),
	Data.new(
		"title2",
		[
			"info 1",
			"info2",
		],
	),
]


class tmp:
	var str: String:
		set(v):
			str = v
			print_debug("str = ", str)
	var num: int
	
	func _init(s: String, n: int) -> void:
		str = s
		num = n


func _ready() -> void:
	item.data = data_array[0]
	item_2.data = data_array[1]
	
	var t1 := tmp.new("ff", 1)
	var t2 := t1
