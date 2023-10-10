extends Node3D
class_name MapPath

var start_node : MapNode
var end_node : MapNode

var state = "disabled" #Stati possibili: traveled, enabled, disabled


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_nodes(s_node, e_node):
	start_node = s_node
	end_node = e_node
	_change_state()


func _change_state():
	if start_node != null and end_node != null:
		if end_node.state == "unreachable":
			state = "disabled"
		elif end_node.state == "reachable":
			if start_node.state == "current":
				state = "enabled"
			else:
				state = "disabled"
		elif end_node.state == "current" or end_node.state == "traveled":
			if start_node.state == "current" or start_node.state == "traveled":
				state = "traveled"
			else:
				state = "disabled"
	
	_change_appearance()


func _change_appearance():
	if state == "traveled":
		$Mesh.material_override = preload("res://materials/map_path_traveled.tres")
	elif state == "enabled":
		$Mesh.material_override = preload("res://materials/map_path_enabled.tres")
	elif state == "disabled":
		$Mesh.material_override = preload("res://materials/map_path_disabled.tres")
