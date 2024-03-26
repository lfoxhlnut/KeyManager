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


static func from_string(s: String) -> Data:
	var pieces := s.split(delimiter)
	var _title: String = pieces[0]
	var _info: Array[String] = []
	for i: int in range(1, pieces.size()):
		_info.append(pieces[i])
	return Data.new(_title, _info)
