extends Node2D
class_name Class

var id : String
var object_class_name : String
var description : String
var time : int
var icon : Texture
var method : String
var type : String

func _set_icon():
	var icon_path = str("res://assets/icons/class_icons/", id, "_icon.png")
	icon = load(icon_path)

#Costruttore
func set_class(input_id : String, input_name: String, input_description : String, input_time : int, input_method : String, input_type : String):
	id = input_id
	object_class_name = input_name
	description = input_description
	time = input_time
	_set_icon()
	method = input_method
	type = input_type


#Costruttore con solo stringhe
func set_class_using_strings(input_id : String, input_name: String, input_description : String, input_time : String, input_method : String, input_type : String):
	id = input_id
	object_class_name = input_name
	description = input_description
	time = int(input_time)
	_set_icon()
	method = input_method
	type = input_type


func get_type():
	return type
