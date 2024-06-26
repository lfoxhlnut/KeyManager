class_name Data
extends RefCounted

# title 和 info 里就不能出现反引号了
const delimiter = "`"

var title: String
var info: PackedStringArray = []:
	set(v):
		info = v.duplicate()
# "valid" can be replaced like this: {data=data, valid=true}.
var valid := true	# 用于判定该 Data 是否是用户输入的(逻辑由返回 Data 的函数/信号等处理)

func _init(_title: String = "", _info: Array[String] = []) -> void:
	title = _title
	info = _info


func is_empty() -> bool:
	return title.is_empty() and info.is_empty()


# TODO: 重写此方法, 现在的阅读起来不是很友好
func _to_string() -> String:
	var info_str := ""
	if info.size() > 0:
		info_str = "%s%s" % [delimiter, delimiter.join(info)]
	return title + info_str


static func from_string(s: String) -> Data:
	var pieces := s.split(delimiter)
	var _title: String = pieces[0]
	var _info: Array[String] = []
	for i: int in range(1, pieces.size()):
		_info.append(pieces[i])
	return Data.new(_title, _info)


func to_dict() -> Dictionary:
	return {
		title=title,
		info=info,
	}


static func from_dict(d: Dictionary) -> Data:
	var res := Data.new()
	res.title = d["title"]
	var type_id: int = typeof(d["info"])
	assert(type_id == TYPE_PACKED_STRING_ARRAY)
	res.info = d["info"]
	return res
