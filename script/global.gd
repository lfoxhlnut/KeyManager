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

const SAVE_PATH = "res://tmp_save.txt"
const SAVE_KEY = "222"

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

func save(data_dict := {}) -> void:
	var save_file := FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, SAVE_KEY)
	if save_file == null:
		print_debug("存档失败, 错误代码 %s" % FileAccess.get_open_error())
	save_file.store_pascal_string(JSON.stringify(data_dict))
	save_file.close()


func load_save() -> Dictionary:
	var res := {}
	var save_file := FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, SAVE_KEY)
	if save_file == null:
		print_debug("读取失败, 错误代码 %s" % FileAccess.get_open_error())
	var t: Dictionary = JSON.parse_string(save_file.get_pascal_string())
	print_debug("\n\n what is read:", t)
	for key: String in t:
		var data_arr: Array[Data] = []
		print_debug("\n\n t[%s] is %s" % [key, t[key]])
		if t[key] is String:
			t[key] = [t[key]]
		for i: String in t[key]:
			data_arr.append(Data.from_string(i))
			assert(data_arr[-1] is Data)
		print_debug("\n\n what is converted:", data_arr)
		res[key] = data_arr.duplicate()
	
	save_file.close()
	return res
