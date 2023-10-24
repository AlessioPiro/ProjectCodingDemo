extends Node2D
class_name EnemyInfo

var id : String
var enemy_name : String
var description : String
var type : String
var hp : int
var atk : int
var def : int
var luk : int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_enemy_info(input_id : String, input_enemy_name : String, input_description : String, input_type : String, input_hp : int, input_atk : int, input_def : int, input_luk : int):
	id = input_id
	enemy_name = input_enemy_name
	description = input_description
	type = input_type
	hp = input_hp
	atk = input_atk
	def = input_def
	luk = input_luk

func get_id() -> String:
	return id

func get_enemy_name() -> String:
	return enemy_name

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
