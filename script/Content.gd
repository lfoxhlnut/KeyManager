extends Control



@onready var title: TabBar = $Title
@onready var v_box: VBoxContainer = $VBoxContainer


func _ready() -> void:
	var t := Data.new("4", ["f", "中1文"])
	print(t)

func initialize() -> void:
	pass
