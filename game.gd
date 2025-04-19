extends Node2D

@onready var unit: Node2D = $Unit
@onready var astar: Node2D = $Astar
@onready var target: Sprite2D = $Target

func _ready() -> void:
	var path = astar.find_path(unit.global_position, target.global_position)
	unit.set_path(path)
	#unit.set_path([Vector2(150, 150), Vector2(600,600)])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("set_Target"):
		target.global_position = get_global_mouse_position()
		var path = astar.find_path(unit.global_position, target.global_position)
		unit.set_path(path)
