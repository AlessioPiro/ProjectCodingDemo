extends Node2D
class_name Package

var id : String
var package_name : String
var price : int
var rarity : int
var locked_description : String
var unlocked_description : String
var classes : Array
var icon : Texture
var is_locked : bool = true


func _set_icon():
	var icon_path = str("res://assets/icons/package_icons/", id, "_icon.png")
	icon = load(icon_path)

#Costruttore di Package
func set_package(input_id : String, input_name : String, input_price : int, input_rarity : int, input_locked_description : String, input_unlocked_description : String, input_classes : Array[String], input_is_locked : bool):
	id = input_id
	package_name = input_name
	price = input_price
	rarity = input_rarity
	locked_description = input_locked_description
	unlocked_description = input_unlocked_description
	classes = input_classes
	_set_icon()
	is_locked = input_is_locked


#Costruttore di Package con solo stringhe
func set_package_using_strings(input_id : String, input_name : String, input_price : String, input_rarity : String, input_locked_description : String, input_unlocked_description : String, input_classes : String, input_is_locked : String):
	id = input_id
	package_name = input_name
	price = int(input_price)
	rarity = int(input_rarity)
	locked_description = input_locked_description
	unlocked_description = input_unlocked_description
	
	input_classes = input_classes.trim_prefix("[").trim_suffix("]")
	classes = Array(input_classes.split(","))
	
	_set_icon()
	
	if input_is_locked == "true":
		is_locked = true
	else:
		is_locked = false
