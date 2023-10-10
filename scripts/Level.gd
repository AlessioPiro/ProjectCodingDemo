extends Node2D
class_name Level

var id : String
var level_name : String
var description : String
var enemies
var min_enemies_level : int
var max_enemies_level : int
var map_skin_name : String
var arenas
var boss_arenas
var treasures
var unknown_events
var packages
var code_pieces


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_level():
	pass

func set_level_by_dictionary(level_dictionary : Dictionary):
	id = level_dictionary.get("id")
	level_name = level_dictionary.get(str(Global.language, "_name"))
	description = level_dictionary.get(str(Global.language, "_description"))
	enemies = level_dictionary.get("enemies")
	min_enemies_level = level_dictionary.get("min_enemies_level")
	max_enemies_level = level_dictionary.get("max_enemies_level")
	map_skin_name = level_dictionary.get("map_skin_name")
	arenas = level_dictionary.get("arenas")
	boss_arenas = level_dictionary.get("boss_arenas")
	treasures = level_dictionary.get("treasures")
	unknown_events = level_dictionary.get("unknown_events")
	packages = level_dictionary.get("packages")
	code_pieces = level_dictionary.get("code_pieces")


func get_id() -> String:
	return id

func get_level_name() -> String:
	return level_name

func get_description() -> String:
	return description

func get_enemies_ids() -> Array:
	if enemies.size() == 1 and enemies[0] == "all":
		return Global.enemies_infos.keys()
	else:
		return enemies

func get_enemies_infos() -> Dictionary:
	if enemies.size() == 1 and enemies[0] == "all":
		return Global.enemies_infos
	else:
		var dictionary = {}
		for enemy_id in enemies:
			dictionary[enemy_id] = Global.enemies_infos.get(enemy_id)
		return dictionary

func get_min_enemies_level() -> int:
	return min_enemies_level

func get_max_enemies_level() -> int:
	return max_enemies_level

func get_map_skin_name() -> String:
	return map_skin_name

func get_arenas() -> Array:
	return arenas

func get_boss_arenas() -> Array:
	return boss_arenas

func get_treasures() -> Array:
	return treasures

func get_unknown_events_ids() -> Array:
	if enemies.size() == 1 and enemies[0] == "all":
		return Global.unknown_events.keys()
	else:
		return unknown_events

func get_packages() -> Array:
	if packages.size() == 1 and packages[0] == "all":
		return Global.packages
	return packages

func get_code_pieces() -> Array:
	if code_pieces.size() == 1 and code_pieces[0] == "all":
		return Global.code_pieces
	return code_pieces 
