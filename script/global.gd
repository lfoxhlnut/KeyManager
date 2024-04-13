extends Node

const DEBUG = true

# NOTE:这些似乎有问题/
#var WIN_WIDTH: float = ProjectSettings.get_setting("display/window/size/viewport_width")
#var WIN_HEIGHT: float = ProjectSettings.get_setting("display/window/size/viewport_height")
#var WIN_SIZE: Vector2:
	#get:
		#return Vector2(WIN_WIDTH, WIN_HEIGHT)


const WIN_WIDTH = 1080
const WIN_HEIGHT = 640
const WIN_SIZE = Vector2(WIN_WIDTH, WIN_HEIGHT)

const DEFAULT_SAVE_PATH = "user://"
const DEFAULT_SAVE_FILENAME = "save.dat"
const DEFAULT_CONFIG_FILENAME = "config.cfg"
var _config_path := DEFAULT_SAVE_PATH.path_join(DEFAULT_CONFIG_FILENAME)
@onready var config := ConfigFile.new()


func _ready() -> void:
	var err := config.load(_config_path)

	if err != OK:
		print_debug("fail to load config file. err code: ", err)


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


# 不适合用内置的 inst_to_dict(), 因为 JSON 默认将 Data 转换成 str, 且没有标注, 所以是不可逆的
## 把一个字典里的所有 Data 和 Array[Data] 转换成字典(通过 Data.to_dict())
## 假设含有一个 Data 的 Array 就是 Array[Data]
## 假设不包含 Packed***Array 一类
func normalize_dict(d: Dictionary) -> Dictionary:
	var res := {}
	for key in d:
		var val
		if d[key] is Data:
			val = (d[key] as Data).to_dict()
			val["type"] = "Data"
			print_debug("encounter data")
		# 假设含有一个 Data 的 Array 就是 Array[Data]
		elif d[key] is Array and d[key][0] is Data:
			var arr: Array = d[key]
			val = {
				type="Array[Data]",
				num=arr.size(),
			}
			print_debug("encounter arr data")
			for i: int in arr.size():
				val[i]=arr[i].to_dict()
		elif d[key] is Dictionary or d[key] is Array:
			# 嵌套的类型就递归, 此函数只处理 Data, Array[Data] 和其他末项
			# 其实包含 packed array 也能处理, 简单点可以判断 typeof(d[key]) 的范围, 但是解码也麻烦, 暂时不涉及就不管了
			val = normalize_dict(d[key])	# fuck, 不好处理 array 的递归, 这个函数想法暂时破产了
			## 暂时废弃
		else:
			val = d[key]
		
		res[key] = val
	return res


## 暂时废弃
## 与上面的方法相对应, 把应该是 Data/Array[Data] 的字典转换成 Data/Array[Data]
func restore_normalized_dict(d: Dictionary) -> Dictionary:
	var res := {}
	for key in d:
		var val
		if d[key] is Dictionary and d[key].has("type"):
			print_debug("here")
			if d[key]["type"] == "Data":
				val = Data.from_dict(d[key])
				#print_debug(val)
			else:	# d[key]["type"] == "Array[Data]"
				val = []
				for i: int in d[key]["num"]:
					val.append(Data.from_dict(d[key][i] as Dictionary))
		else:
			val = d[key]
		res[key] = val
	return res
