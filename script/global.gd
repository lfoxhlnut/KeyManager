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

func _ready() -> void:
	pass


func get_hud() -> HUD:
	return get_node("../Main/HUD") as HUD
