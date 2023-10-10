extends Node2D
class_name CodePiece

var id : String
var code_piece_name : String
var price : int
var rarity : int = 1
var description : String
var category : String
var piece_texts : Array
var icon : Texture
var num_connections : int = 0
var types : Array
var num_iterations : int


func _set_icon():
	var icon_name
	if category == "if" or category == "else_if":
		icon_name = category
	else:
		icon_name = id
	var icon_path = str("res://assets/icons/code_piece_icons/", icon_name, "_icon.png")
	icon = load(icon_path)

#Costruttore
func set_code_piece(input_id : String, input_name : String, input_price : int, input_rarity : int, input_description : String, input_category : String, input_piece_texts : Array[String], input_num_connections : int, input_types : Array[String], input_num_iterations : int):
	id = input_id
	code_piece_name = input_name
	price = input_price
	rarity = input_rarity
	description = input_description
	category = input_category
	piece_texts = input_piece_texts
	_set_icon()
	num_connections = input_num_connections
	types = input_types
	num_iterations = input_num_iterations

#Costruttore con solo stringhe
func set_code_piece_using_strings(input_id : String, input_name : String, input_price : String, input_rarity : String, input_description : String, input_category : String, input_piece_texts : String, input_num_connections : String, input_types : String, input_num_iterations : String):
	id = input_id
	code_piece_name = input_name
	price = int(input_price)
	rarity = int(input_rarity)
	description = input_description
	category = input_category
	
	input_piece_texts = input_piece_texts.trim_prefix("[").trim_suffix("]")
	piece_texts = Array(input_piece_texts.split(","))
	
	_set_icon()
	num_connections = int(input_num_connections)
	
	input_types = input_types.trim_prefix("[").trim_suffix("]")
	types = Array(input_types.split(","))
	if types[0] == "": #Se l'array è vuoto, Godot salva comunque un elemento vuoto al suo interno. Di conseguenza, è necessario rimuoverlo
		types.remove_at(0)
	
	num_iterations = int(input_num_iterations)
