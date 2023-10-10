extends Node2D
class_name HealthComponent

##force_hp : Forza gli hp dell'elemento con i dati immessi nei campi appositi; obtain_hp_from_element_id: Recupera i dati dal database apposito; player_hp: Recupera gli HP del giocatore da Global; init_by_stats_component: Si lascia inizializzare da StatsComponent.
@export_enum("force_hp", "obtain_hp_from_element_id", "indipendent_player_hp", "init_by_stats_component") var initialization_mode = "force_hp"

@export_group("Force HP Settings")
@export var forced_max_hp : int = 100
@export var forced_starting_hp : int = 100

@export_group("Obtain HP From Element ID Settings")
@export_enum("character", "enemy") var element_category = "character"
@export var element_id : String
@export var element_level : int

var max_hp = 100
var current_hp = 100

var parent_instance_id

# Called when the node enters the scene tree for the first time.
func _ready():
	init()
	_connect_signals()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Tutti i segnali necessari vengono collegati al BattleElementSignalManager
func _connect_signals():
	parent_instance_id = get_parent().get_instance_id()
	var battle_element_signal_manager = Global.scene_signal_manager.get_battle_element_signal_manager(parent_instance_id)
	
	battle_element_signal_manager.damage.connect(on_damage)
	battle_element_signal_manager.heal.connect(on_heal)

#Inizializzazione del Component
func init():
	match initialization_mode:
		"force_hp":
			max_hp = forced_max_hp
			current_hp = forced_starting_hp
			if current_hp > max_hp: current_hp = max_hp
		
		"obtain_hp_from_element_id":
			var st_calc = StatsCalculator.new()
			max_hp = st_calc.calculate_all_stats(element_category, element_id, element_level)
		
		"indipendent_player_hp":
			max_hp = Global.player_hp
			current_hp = Global.game_player_hp
		
		"init_by_stats_component":
			pass


#Alla ricezione di un danno, abbassa gli HP
func on_damage(damage_amount : int, is_super_effective : bool, is_not_effective : bool, is_crit: bool):
	current_hp -= damage_amount
	Global.scene_signal_manager.get_battle_element_signal_manager(parent_instance_id).hp_lowered.emit(damage_amount)
	
	if current_hp < 0: 
		current_hp = 0
	
	if current_hp == 0:
		Global.scene_signal_manager.get_battle_element_signal_manager(parent_instance_id).death.emit()


#Alla ricezione di una cura, alza gli HP
func on_heal(heal_amount : int, is_percentage : bool):
	
	if is_percentage:
		heal_amount = int(round((max_hp/100) * heal_amount))
	
	current_hp += heal_amount
	Global.scene_signal_manager.get_battle_element_signal_manager(parent_instance_id).hp_recover.emit(heal_amount)
	
	if current_hp > max_hp: 
		current_hp = max_hp


#Chiamata da uno StatsComponent. Funziona solo se la modalità di inizializzazione è "init_by_stats_component"
func init_by_stats_component(input_hp_max : int):
	if initialization_mode == "init_by_stats_component":
		max_hp = input_hp_max
		if get_parent().is_in_group("player"):
			current_hp = Global.game_player_hp
		else:
			current_hp = input_hp_max


func get_hp() -> int:
	return current_hp
