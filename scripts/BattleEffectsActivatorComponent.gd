extends Node2D

@export_enum("on_ready", "on_collision") var activation_mode = "on_ready"
#@export_enum("only_stricken") var damage_mode = "only_stricken"

@export_group("Activation On Collision Settings")
@export_enum("same_as_target", "force") var choosing_targets_mode = "same_as_target"
@export var forced_targets_groups : Array[String]

var caller_instance_id : int #Instance_id di chi ha evocato inizialmente la mossa/l'oggetto di guici a cui tale Component è collegato
var opponents_groups = [] #Array contenente i gruppi degli avversari

var battle_effects = [] #Array di BattleEffects
var parent_node #Nodo padre del Component. Solitamente una Mossa o un BattleObject (Bullet, ecc.)
var parent_instance_id #Instance_id del nodo padre

# Called when the node enters the scene tree for the first time.
func _ready():
	#Ottiene il nodo padre
	parent_node = get_parent()
	#Connette i segnali
	_connect_signals()
	#Si inizializza
	_initialize()
	#Riempie l'array dei BattleEffects
	_fill_battle_effects_array()
	
	if activation_mode == "on_ready":
	#Per ogni BattleEffects verifica il da farsi e interagisce con i component del/dei target
		activate_battle_effects(-1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


# Tutti i segnali necessari vengono collegati al BattleElementSignalManager
func _connect_signals():
	parent_instance_id = get_parent().get_instance_id()
	var battle_element_signal_manager = Global.scene_signal_manager.get_battle_element_signal_manager(parent_instance_id)
	
	battle_element_signal_manager.collision.connect(on_collision)


func on_collision(area : Area3D):
	if activation_mode == "on_collision":
		match choosing_targets_mode:
			"same_as_target":
				if !opponents_groups.is_empty():
					for group in opponents_groups:
						if area.get_parent().is_in_group(group):
							activate_battle_effects([area.get_parent().get_instance_id()])
							
							###############################
							get_parent().queue_free()
							###############################
							
							return
						
			"force":
				pass
	
	#######################################################
	if area.is_in_group("invisible_wall"):
		get_parent().queue_free()
	#######################################################
	

func _initialize():
	caller_instance_id = parent_node.get_caller_instance_id()
	if parent_node.has_method("get_opponents_groups"):
		opponents_groups = parent_node.get_opponents_groups()


func _fill_battle_effects_array():
	for child in get_children():
		if child.is_in_group("battle_effect"):
			battle_effects.append(child)


#Attivato o all'instanziazione della mossa o da un segnale che ha la possibilità di comunicare i target (id delle istanze dei target)
func activate_battle_effects(input_targets):
	#Per ogni battle_effect...
	for battle_effect in battle_effects:
		#Identifichiamo il/i target dell'effetto
		var targets_instance_ids = []
		##Nel caso il target sia settato su "stricken" ma questo component non ha ricevuto alcun target da esterni, allora passa ad "opponent"
		if battle_effect.target == "stricken" and typeof(input_targets) == TYPE_INT:
			battle_effect.target = "opponent"
		
		match battle_effect.target:
			"opponent":
				#Per ogni nodo dell'albero controlla se fa parte di uno dei gruppi degli opponent e aggiunge il suo instance_id all'array dei target
				for group in opponents_groups:
					var node_array = get_tree().get_nodes_in_group(group)
					for node in node_array:
						targets_instance_ids.append(node.get_instance_id())
			"self":
				targets_instance_ids.append(caller_instance_id)
			"stricken":
				targets_instance_ids = input_targets
		
		#Verifica di che effetto si tratta e sceglie il comportamento da adottare
		match battle_effect.get_effect_type():
			"damage":
				_activate_damage(caller_instance_id, targets_instance_ids, battle_effect)
			"healing":
				_activate_healing(targets_instance_ids, battle_effect)
			"support":
				_activate_support(targets_instance_ids, battle_effect)


func _activate_damage(caller, targets, battle_effect):
	#Crea DamageCalculator
	var dam_calc = DamageCalculator.new()
	
	#Recuperiamo i dati relativi all'attacco
	var attack_damage_power = battle_effect.damage_power
	var attack_damage_type = battle_effect.damage_type
	
	#Ottieni le statistiche del caller
	var caller_node = instance_from_id(caller)
	var caller_stats = {"hp" : 50,"atk" : 50, "def" : 50, "luk" : 50}
	var caller_type = "fire"
	if caller_node.has_node("StatsComponent"):
		caller_stats = caller_node.get_node("StatsComponent").get_stats()
		caller_type = caller_node.get_node("StatsComponent").get_type()
	
	#Ricevi dal DamageCalculator il danno per ogni target ed emetti il segnale del danno
	for target_id in targets:
		var target_node = instance_from_id(target_id)
		var target_stats = {"hp" : 50,"atk" : 50, "def" : 50, "luk" : 50}
		var target_type = "fire"
		if target_node.has_node("StatsComponent"):
			target_stats = target_node.get_node("StatsComponent").get_stats()
			target_type = target_node.get_node("StatsComponent").get_type()
		
		var damage_data : Dictionary = dam_calc.calculate_damage(caller_stats, caller_type, target_stats, target_type, attack_damage_power, attack_damage_type)
		Global.scene_signal_manager.get_battle_element_signal_manager(target_id).damage.emit(damage_data.get("damage"), damage_data.get("is_super_effective"), damage_data.get("is_not_effective"), damage_data.get("is_crit"))


func _activate_healing(targets, battle_effect):
	
	#Recupero dei dati della cura in base al BattleEffect
	var is_percentage = battle_effect.is_healing_percentage
	var healing_amount
	if is_percentage:
		healing_amount = battle_effect.heal_percentage
	else:
		healing_amount = battle_effect.heal_hp
	
	#Emette un segnale per ogni target
	for target in targets:
		Global.scene_signal_manager.get_battle_element_signal_manager(target).heal.emit(healing_amount, is_percentage)


func _activate_support(targets, battle_effect):
	var stat_up = battle_effect.stat_up
	var buff_debuff_level = battle_effect.buff_debuff_level
	var stat_name = battle_effect.stat_name
	
	for target in targets:
		if stat_up:
			Global.scene_signal_manager.get_battle_element_signal_manager(target).buff_request.emit(buff_debuff_level, stat_name)
		else:
			Global.scene_signal_manager.get_battle_element_signal_manager(target).debuff_request.emit(buff_debuff_level, stat_name)
	
	
	
