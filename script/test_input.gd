extends Control

func _ready() -> void:
	var btn := Button.new()
	btn.text = "1111111"
	#btn.global_position = Vector2(200, 200)
	btn.pressed.connect(func():
		print("pressed")
	)
	Global.add_child(btn)
