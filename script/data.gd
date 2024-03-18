class_name Data
extends RefCounted

var title: String
#var info_num: int
var info: Array[String] = []:
	set(v):
		info = v.duplicate()


func _init(_title: String = "", _info: Array[String] = []) -> void:
	title = _title
	info = _info

