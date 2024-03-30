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

func _ready() -> void:
	pass


func get_hud() -> HUD:
	return get_node("../Main/HUD") as HUD

"""
data_dict = {
	"class1": [
		Data.new("title1", ["fff", "11中文"]),
		Data.new("222", ["password", "11中文"]),
		Data.new("3", ["password", "11中文"]),
	],
	"kirov reporting": [
		Data.new("vehicle", ["fff", "11中文"]),
		Data.new("222", ["password", "11中文"]),
		Data.new("3", ["password", "11中文"]),
	],
}
var encoded := JSON.stringify(data_dict)
var decoded: Dictionary = JSON.parse_string(encoded)
print(decoded)
print(typeof(decoded["class1"]))	# Array
print(decoded["class1"][0] is String)	# true
"""

func save(data_dict: Dictionary, passwd: String, save_path: String) -> void:
	var save_file := FileAccess.open_encrypted_with_pass(save_path.path_join(DEFAULT_SAVE_FILENAME), FileAccess.WRITE, passwd)
	if save_file == null:
		print_debug("Fail to save. Error code is %s" % FileAccess.get_open_error())
		return
	save_file.store_pascal_string(JSON.stringify(data_dict))
	save_file.close()


func load_save(passwd: String, save_path: String) -> Dictionary:
	print_debug("load pswd:", passwd)
	var res := {}
	var save_file := FileAccess.open_encrypted_with_pass(save_path.path_join(DEFAULT_SAVE_FILENAME), FileAccess.READ, passwd)
	if save_file == null:
		print_debug("Fail to load save file. Error code is %s" % FileAccess.get_open_error())
		return {}
	var t: Dictionary = JSON.parse_string(save_file.get_pascal_string())
	#print_debug("\n\n what is read:", t)
	for key: String in t:
		var data_arr: Array[Data] = []
		#print_debug("\n\n t[%s] is %s" % [key, t[key]])
		if t[key] is String:
			t[key] = [t[key]]
		for i: String in t[key]:
			data_arr.append(Data.from_string(i))
			assert(data_arr[-1] is Data)
		#print_debug("\n\n what is converted:", data_arr)
		res[key] = data_arr.duplicate()
	
	save_file.close()
	return res
