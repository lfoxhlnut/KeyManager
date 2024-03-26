class_name Data
extends RefCounted

# title 和 info 里就不能出现反引号了
const delimiter = "`"

var title: String
#var info_num: int
var info: PackedStringArray = []:
	set(v):
		info = v.duplicate()


func _init(_title: String = "", _info: Array[String] = []) -> void:
	title = _title
	info = _info


func _to_string() -> String:
	return "%s%s%s" % [title, delimiter, delimiter.join(info)]


func from_string(s: String) -> void:
	var pieces := s.split(delimiter)
	title = pieces[0]
	info.clear()
	for i: int in range(2, pieces.size()):
		info.append(pieces[i])
