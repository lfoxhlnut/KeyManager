extends Node

const DEBUG = true

var WIN_WIDTH: float:
	get:
		if OS.has_feature("editor"):
			return ProjectSettings.get_setting("display/window/size/window_width_override")
		return ProjectSettings.get_setting("display/window/size/viewport_width")
var WIN_HEIGHT: float:
	get:
		if OS.has_feature("editor"):
			return ProjectSettings.get_setting("display/window/size/window_height_override")
		return ProjectSettings.get_setting("display/window/size/viewport_height")
var WIN_SIZE: Vector2:
	get:
		return Vector2(WIN_WIDTH, WIN_HEIGHT)

const DEFAULT_SAVE_PATH = "user://"
const DEFAULT_SAVE_FILENAME = "save.dat"
const DEFAULT_CONFIG_FILENAME = "config.cfg"
var _config_path := DEFAULT_SAVE_PATH.path_join(DEFAULT_CONFIG_FILENAME)
@onready var config := ConfigFile.new()


func _ready() -> void:
	var err := config.load(_config_path)

	if err != OK:
		print_debug("fail to load config file. err code: ", err)
	
	@warning_ignore("unused_variable")
	var max_size := DisplayServer.screen_get_usable_rect().size
	
	match OS.get_name():
		"Android":
			pass

func _exit_tree() -> void:
	save_config()


func get_hud() -> HUD:
	return get_node("../Main/HUD") as HUD


func save_data(data_dict: Dictionary, passwd: String, save_path: String) -> void:
	var save_file := FileAccess.open_encrypted_with_pass(save_path.path_join(DEFAULT_SAVE_FILENAME), FileAccess.WRITE, passwd)
	if save_file == null:
		print_debug("Fail to save. Error code is %s" % FileAccess.get_open_error())
		return
	save_file.store_pascal_string(JSON.stringify(data_dict))
	save_file.close()


func save_config(path: String = _config_path) -> void:
	config.save(path)


func load_save(passwd: String, save_path: String) -> Dictionary:
	var save_file := FileAccess.open_encrypted_with_pass(save_path.path_join(DEFAULT_SAVE_FILENAME), FileAccess.READ, passwd)
	if save_file == null:
		print_debug("Fail to load save file. Error code is %s" % FileAccess.get_open_error())
		return {}
	return JSON.parse_string(save_file.get_pascal_string())


## 序列化字典(通过 var_to_str), 保留 Array 的类型(如果有的话)
## 允许的变量类型可通过 type_serializable() 判定
## 假设字典的键都是字符串类型
func serialize_dict(d: Dictionary) -> Dictionary:
	var res := {
		_type="Dictionary",
	}
	for key in d:
		res[key] = _serialize_element(d[key])
		
	return res


func type_serializable(type_id: int) -> bool:
	return type_id <= TYPE_OBJECT or type_id in [TYPE_ARRAY, TYPE_DICTIONARY]


## 与 serialize_dict() 类似, 序列化数组
func serialize_arr(arr: Array) -> Dictionary:
	# Probably useful: Array::is_typed().
	var type_id := arr.get_typed_builtin()
	# object 之前的都是内置类型, 预期可以以合适的方式自动序列化和反序列化
	assert(type_serializable(type_id))
	
	var res := {
		_type="Array",
		_size=arr.size(),
		_type_id=type_id,
	}
	
	# object 类型要手动处理
	if type_id == TYPE_OBJECT:
		# 因为目前 gd 没有获取 class_name 的方法, 只能获取基类的名称
		res._element_base_type=arr.get_typed_class_name()
		res._element_type = ""
		res._element_script = arr.get_typed_script().resource_path
		if arr is Array[Data]:
			res._element_type = "Data"
	
	for id: int in arr.size():
		res[str(id)] = _serialize_element(arr[id])
	
	return res


func _serialize_element(ele: Variant) -> Dictionary:
	var type_id := typeof(ele)
	assert(type_serializable(type_id))
	var val: Dictionary
	
	match type_id:
		TYPE_DICTIONARY:
			val = serialize_dict(ele)
		TYPE_ARRAY:
			val = serialize_arr(ele)
		_:
			val = serialize_others(ele)
			
	return val


## 与 serialize_dict() 类似, 序列化字典和数组(二者是容器)以外的变量
func serialize_others(ele: Variant) -> Dictionary:
	var val = {
			_type="others",	# 其实是什么都无所谓, 只要有这个字段就行
			_type_id=typeof(ele),
			_val=var_to_str(ele),
		}
	
	# object 的子类需要手动处理, 假定只会出现 Data
	if ele is Data:
		val["_type"] = "Data"
	
	return val


## 与 serialize_dict 方法相对应, 反序列化字典, 可以正确处理带类型的 Array
func deserialize_dict(d: Dictionary) -> Dictionary:
	assert(d._type == "Dictionary")
	var res := {}
	
	for key: String in d:
		if key == "_type":
			continue
		res[key] = _deserialize_element(d[key])
	
	return res


## 类似 deserialize_dict(), 反序列化数组
func deserialize_arr(d: Dictionary) -> Array:
	assert(d._type == "Array")
	var res: Array
	d._type_id = d._type_id as int
	d._size = d._size as int
	
	# 给数组赋上类型, object 的子类(暂时只有 Data)需要手动处理
	if d._type_id == TYPE_OBJECT:
#print(Array([], TYPE_OBJECT, "RefCounted", load("res://script/data.gd")) is Array[Data]) # true
		var script = null
		if d._element_type == "Data":
			script = load(d._element_script)
		# 这里必须手动转换成 string name 类型, 不然会报错, 很奇怪, 为什么这里不能自动转换呢
		res = Array([], TYPE_OBJECT, StringName(d._element_base_type), script)
	else:
		res = Array([], d._type_id, "", null)
	
	for id: int in range(d._size):
		res.append(_deserialize_element(d[str(id)]))
	return res


func _deserialize_element(ele: Dictionary) -> Variant:
	assert(ele.has("_type"))
	var val
	match ele._type:
		"Dictionary":
			val = deserialize_dict(ele)
		"Array":
			val = deserialize_arr(ele)
		_:
			val = deserialize_others(ele)
	return val


## 类似 deserialize_dict(), 反序列化字典和数组以外的变量
func deserialize_others(ele: Dictionary) -> Variant:
	ele._type_id = ele._type_id as int
	var val = str_to_var(ele._val)
	
	if ele._type_id == TYPE_OBJECT:
		if ele._type == "Data":
			return val as Data
	
	return type_convert(val, ele._type_id)
