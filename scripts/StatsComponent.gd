extends Node2D

@export_enum("forced", "by_id") var initialization_mode = "by_id"

@export_group("Forced Initialization Settings")
@export var forced_hp : int = 100
@export var forced_atk : int = 100
@export var forced_def : int = 100
@export var forced_luk : int = 100
@export_enum("fire", "water", "grass", "normal") var forced_type = "normal"
##Livello del nemico. Se uguale a -1, il livello non viene forzato, rimanendo quello stabilito dalla partita
@export var forced_level : int = -1 


@export_group("Initialization By ID Settings")
@export_enum("character", "enemy") var element_category = "enemy"
@export var element_id : String

var element = null

var base_stats = {"hp" : 0, "atk" : 0, "def" : 0, "luk" : 0} #Statistiche di base
var final_stats = {} #Statistiche calcolate a seconda del livello dell'elemento
var level : int = 5 #Livello dell'elemento
var type : String = "normal" #Tipo dell'elemento

var buff_levels = {"hp" : 0, "atk" : 0, "def" : 0, "luk" : 0} #Buff/Debuff alle statistiche dato dall'effetto di mosse. N buff = (1 + 0.25N); N Debuff = 1/(1+(N/2))

var parent_instance_id

# Called when the node enters the scene tree for the first time.
func _ready():
	_init_component()
	_init_health_component()
	_init_hp_bar_component()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#INIZIALIZZAZIONE

# Tutti i segnali necessari vengono collegati al BattleElementSignalManager
func _connect_signals():
	var parent_instance_id = get_parent().get_instance_id()
	var battle_element_signal_manager = Global.scene_signal_manager.get_battle_element_signal_manager(parent_instance_id)
	
	battle_element_signal_manager.buff_request.connect(on_buff)
	battle_element_signal_manager.debuff_request.connect(on_debuff)


func _init_component():
	var st_calc = StatsCalculator.new()
	match initialization_mode:
		
		"forced":
			base_stats["hp"] = forced_hp
			base_stats["atk"] = forced_atk
			base_stats["def"] = forced_def
			base_stats["luk"] = forced_luk
			type = forced_type
			if forced_level > -1: 
				level = forced_level
			final_stats = st_calc.calculate_all_stats_from_stats_dictionary(base_stats, level)
		
		"by_id":
			match element_category:
				"character":
					element = Global.playable_characters_infos[element_id]
					level = Global.player_level
				"enemy":
					element = Global.enemies_infos[element_id]
					level = get_tree().root.get_node("/root/BattleScene").enemy_level
			base_stats["hp"] = element.get_hp()
			base_stats["atk"] = element.get_atk()
			base_stats["def"] = element.get_def()
			base_stats["luk"] = element.get_luk()
			type = element.get_type()
			final_stats = st_calc.calculate_all_stats(element_category, element_id, level)

func _init_health_component():
	var health_component = get_parent().get_node_or_null("HealthComponent")
	if health_component != null:
		health_component.init_by_stats_component(final_stats["hp"])


func _init_hp_bar_component():
	var hp_bar_component = get_parent().get_node_or_null("HPBarComponent")
	if hp_bar_component != null:
		var element_name = " "
		var element_type = "normal"
		if element != null:
			if element.has_method("get_enemy_name"):
				element_name = element.get_enemy_name()
			
			if element.has_method("get_type"):
				element_type = element.get_type()
			
		hp_bar_component.init_by_stats_component(element_name, element_type, element_category, final_stats["hp"])


#RISPOSTE AI SIGNAL


func on_buff(buff_level : int, buff_stat : String):
	buff_levels[buff_stat] += buff_level
	if buff_levels[buff_stat] > Global.max_buff_debuff_level:
		buff_levels[buff_stat] = Global.max_buff_debuff_level
	Global.scene_signal_manager.get_battle_element_signal_manager(parent_instance_id).stat_buffed.emit(buff_level, buff_stat)

func on_debuff(debuff_level : int, debuff_stat : String):
	buff_levels[debuff_stat] -= debuff_level
	if buff_levels[debuff_stat] < -(Global.max_buff_debuff_level):
		buff_levels[debuff_stat] = -(Global.max_buff_debuff_level)
	Global.scene_signal_manager.get_battle_element_signal_manager(parent_instance_id).stat_debuffed.emit(debuff_level, debuff_stat)

#GETTER

func get_stats_no_buff() -> Dictionary:
	return final_stats

func get_base_stats() -> Dictionary:
	return base_stats

#Restituisce le statistiche al netto di buff e debuff
func get_stats() -> Dictionary:
	var buffed_stats = {}
	var iterator = 0
	for stat_name in final_stats.keys():
		
		var buff_level = buff_levels[stat_name]
		
		var buff_multiplier = 1
		if buff_level > 0:
			buff_multiplier = 1 + (0.25 * buff_level)
		elif buff_level < 0:
			buff_multiplier = 1/(1 + (buff_level/2))
		
		buffed_stats[stat_name] = int(round(final_stats.values()[iterator] * buff_multiplier))
		
		iterator += 1
	
	return buffed_stats

func get_type() -> String:
	return type

func get_level() -> int:
	return level
