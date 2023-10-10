extends Resource
class_name StatsCalculator


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func calculate_all_stats(type : String, id : String, level : int) -> Dictionary:
	
	var element
	var stats = {}
	
	match type:
		"enemy":
			element = Global.enemies_infos.get(id)
		"character":
			element = Global.playable_characters_infos.get(id)
		_:
			return {}
	
	stats["hp"] = calculate_hp(element.get_hp(), level)
	stats["atk"] = calculate_stat(element.get_atk(), level)
	stats["def"] = calculate_stat(element.get_def(), level)
	stats["luk"] = calculate_stat(element.get_luk(), level)
	
	return stats


func calculate_all_stats_from_stats_dictionary(base_stats : Dictionary, level : int) -> Dictionary:
	
	var stats = {}
	
	
	stats["hp"] = calculate_hp(base_stats.get("hp"), level)
	stats["atk"] = calculate_stat(base_stats.get("atk"), level)
	stats["def"] = calculate_stat(base_stats.get("def"), level)
	stats["luk"] = calculate_stat(base_stats.get("luk"), level)
	
	return stats


#Calcolo della singola statistica
func calculate_stat(base_stat : int, level : int) -> int:
	var stat_value = ((2 * base_stat * level)/100) + 5
	return stat_value


#Calcolo degli HP
func calculate_hp(base_stat : int, level : int) -> int:
	var stat_value = ((2 * base_stat * level)/100) + level + 10
	return stat_value
