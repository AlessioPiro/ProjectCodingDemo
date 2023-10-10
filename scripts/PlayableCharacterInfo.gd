extends Node2D
class_name PlayableCharacterInfo

var id : String
var playable_character_name : String
var description : String
var type : String
var hp : int
var atk : int
var def : int
var luk : int
var agi : int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_playable_character_info(input_id : String, input_playable_character_name : String, input_description : String, input_type : String, input_hp : int, input_atk : int, input_def : int, input_luk : int, input_agi : int):
	id = input_id
	playable_character_name = input_playable_character_name
	description = input_description
	type = input_type
	hp = input_hp
	atk = input_atk
	def = input_def
	luk = input_luk
	agi = input_agi


func get_id() -> String:
	return id

func get_playable_character_name() -> String:
	return name

func get_description() -> String:
	return description

func get_type() -> String:
	return type

func get_hp() -> int:
	return hp

func get_atk() -> int:
	return atk

func get_def() -> int:
	return def

func get_luk() -> int:
	return luk

func get_agi() -> int:
	return agi
