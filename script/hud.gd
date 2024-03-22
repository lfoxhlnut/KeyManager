class_name HUD
extends CanvasLayer

var exclusive_mouse := false:
	set(v):
		exclusive_mouse = v
		color_rect.mouse_filter = Control.MOUSE_FILTER_STOP if v else Control.MOUSE_FILTER_IGNORE

@onready var color_rect: ColorRect = $ColorRect
