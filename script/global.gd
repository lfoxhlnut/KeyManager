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


func save(data_dict := {}) -> void:
	var data: File = File.new()
	var err := data.open_encrypted_with_pass(DATA_PATH, File.WRITE, DATA_KEY)
	if err:
		warn("存档失败, 错误代码 %s" % err)
	if data.is_open():
		print_debug("Saving...")
#		print_debug(JSON.print(d))
		data.store_pascal_string(JSON.print(d))
	else:
		print_debug("存档失败", err)
		warn("Can't save datas. Please make sure the data file 「%s」 is not being used." % DATA_PATH)
	data.close()
	data.unreference()
	pass


func load() -> Dictionary:
	var res := {}
	return res
