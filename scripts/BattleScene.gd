extends Node3D

@onready var player_hp_bar = $UI/PlayerUI/PlayerHPBarContainer
@onready var battle_scene_animator = $BattleSceneAnimator
@onready var move_1_button = $UI/PlayerUI/Buttons/Move1Button
@onready var move_2_button = $UI/PlayerUI/Buttons/Move2Button

@onready var enemy_position = $Markers/EnemyPosition
@onready var player_position = $Markers/PlayerPosition

var state : String
#State Machine:
# -introduction: Primo stato della scena. In questo una breve animazione introduce il giocatore alla battaglia. Nessun input avrà effetto in questo stato
# -battle: Stato principale della scena. In questo stato tutti gli input avranno effetto
# -cutscene: Simile ad introduction. Stato in cui nessun input avrà effetto tranne per un possibile skip (da implementare)
# -victory_screen: Stato in cui vengono visualizzati i risultati della battaglia.
# -game_over: Tutti gli input vengono disabilitati fino al cambio scena (con la schermata di game over) 

var enemy_type = "normal"
var moves = {} #Dizionario formato da 3 dizionari (constructor, move1, move2) contenenti "class_id", "iterations" e "reload_time"
var enemy_id : String = "fire_slime"
var enemy_level : int = 5

var reward : int

#Riferimenti ai nodi enemy e player
var enemy
var character

# Called when the node enters the scene tree for the first time.
func _ready():
	#Viene creato un nuovo BattleSignalManager, accessibile tramite Global
	Global.scene_signal_manager = BattleSignalManager.new()
	#!!!Viene generata la reward in caso di vittoria!!!
	_generate_reward()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func import_data_from_previous_scene(transfer_data : Dictionary):
	if transfer_data.has("enemy_id"):
		enemy_id = transfer_data.get("enemy_id")
	if transfer_data.has("enemy_level"):
		enemy_level = transfer_data.get("enemy_level")

#Funzione che si occupa di recuperare i path delle scene definite a tempo di compilazione
func load_nodes_paths() -> Dictionary:
	var nodes_paths = {} #I path di tutti gli elementi da caricare all'inizio della scena
	#Recuperiamo le informazioni del livello che ci servono
	
	#Otteniamo il percorso del modello dell'arena
	var arena_name = Global.get_current_level().get_arenas()[0]
	nodes_paths["arena"] = str("res://assets/game_objects/arenas/", arena_name.capitalize().replace(" ", ""), ".tscn")
	#Otteniamo il percorso del personaggio del giocatore
	nodes_paths["character"] = str("res://assets/game_objects/playable_characters/playable_characters_scenes/", Global.character_id.capitalize().replace(" ", ""), ".tscn")
	#Otteniamo il percorso del nemico del giocatore
	nodes_paths["enemy"] = str("res://assets/game_objects/enemies/enemies_scenes/", enemy_id.capitalize().replace(" ", ""), ".tscn")
	
	return nodes_paths

#Funzione che si occupa di aggiungere all'albero i nodi definiti a tempo di compilazione e caricati dal loader in Global
func add_loaded_nodes_to_tree(loaded_nodes : Dictionary):
	#Aggiungiamo il modello dell'arena all'albero
	if loaded_nodes.has("arena") and loaded_nodes.get("arena") != null:
		var arena = loaded_nodes.get("arena").instantiate()
		add_child(arena)
	#Aggiungiamo il personaggio del giocatore all'albero
	if loaded_nodes.has("character") and loaded_nodes.get("character") != null:
		character = loaded_nodes.get("character").instantiate()
		add_child(character)
		#Setta la posizione iniziale del giocatore
		call_deferred("_set_position_deferred", character, player_position)
	#Aggiungiamo il nemico all'albero
	if loaded_nodes.has("enemy") and loaded_nodes.get("enemy") != null:
		enemy = loaded_nodes.get("enemy").instantiate()
		if enemy.has_node("StatsComponent"):
			var stats_component = enemy.get_node("StatsComponent")
			stats_component.call_deferred("set_enemy_level", enemy_level)
		add_child(enemy)
		call_deferred("_set_position_deferred", enemy, enemy_position)
		call_deferred("_set_enemy_type_deferred", enemy)
		
	#Inizializza la battaglia
	call_deferred("_inizialize_battle")

func _set_position_deferred(node, position_node):
	node.global_position = position_node.global_position

func _set_enemy_type_deferred(enemy):
	if enemy.has_node("StatsComponent"):
		enemy_type = enemy.get_node("StatsComponent").get_type()

#Inizializza la battaglia
func _inizialize_battle():
	#Setta lo stato della scena
	_set_battle_state("introduction")
	#Connetti i segnali al nemico e al player per intercettare eventi cruciali
	_connect_signal()
	#Carica le mosse del giocatore
	_update_player_moves()
	#Inizializza la HP Bar
	player_hp_bar.inizialize_hp_bar()
	#Inizializza i pulsanti delle mosse del giocatore
	move_1_button.inizialize_button(moves.get("move1").get("reload_time"), moves.get("move1").get("class_id") == "empty")
	move_2_button.inizialize_button(moves.get("move2").get("reload_time"), moves.get("move2").get("class_id") == "empty")
	#Chiama la mossa costruttore del giocatore
	launch_player_move("constructor")
	############################################
	battle_scene_animator.play("introduction")
	###########################################

#Connetti i segnali al nemico e al player per intercettare eventi cruciali
func _connect_signal():
	var player_battle_element_signal_manager = Global.scene_signal_manager.get_battle_element_signal_manager(character.get_instance_id())
	var enemy_battle_element_signal_manager = Global.scene_signal_manager.get_battle_element_signal_manager(enemy.get_instance_id())
	
	player_battle_element_signal_manager.death.connect(_on_player_death)
	enemy_battle_element_signal_manager.death.connect(_on_enemy_death)

#Funzione lanciata alla morte del giocatore
func _on_player_death():
	pass

#Funzione lanciata alla morte del nemico
func _on_enemy_death():
	if Global.map_node_movement_to.x == 19:
		$TransitionLayer/TransitionAnimation.play("end_transition")
	else:
		$TransitionLayer/TransitionAnimation.play("victory_transition")

func _update_player_moves():
	#Carichiamo i dati relativi alla mossa costruttore
	moves["constructor"] = Global.get_move("constructor").get_move_info_by_type(enemy_type)
	#Carichiamo i dati relativi alla mossa1
	moves["move1"] = Global.get_move("move1").get_move_info_by_type(enemy_type)
	#Carichiamo i dati relativi alla mossa2
	moves["move2"] = Global.get_move("move2").get_move_info_by_type(enemy_type)

func _set_battle_state(new_state : String):
	state = new_state


func _start_battle():
	#Setta lo stato a "battle"
	_set_battle_state("battle")
	#Attiva i pulsanti
	move_1_button.set_state("on_loading")
	move_2_button.set_state("on_loading")


func _on_battle_scene_animator_animation_finished(anim_name):
	if anim_name == "introduction":
		_start_battle()


func battle_player_launch_move(button : String):
	if button.contains("move_1"):
		#Fai lanciare l'attacco al giocatore
		launch_player_move("move1")
		
		#Fai ripartire la carica del pulsante
		move_1_button.set_state("on_loading")
		
	elif button.contains("move_2"):
		#Fai lanciare l'attacco al giocatore
		launch_player_move("move2")
		
		#Fai ripartire la carica del pulsante
		move_2_button.set_state("on_loading")


var move_iterations = 0
var battle_move_instance
var move_iterations_timer
func launch_player_move(method_name : String):
	#Controlla che in input non sia stata passata una stringa diversa dai 3 nomi dei metodi
	if method_name != "move1" and method_name != "move2" and method_name != "constructor":
		print ("ERROR in launch_player_move function in BattleScene: incorrect method name.")
		return
	
	var class_id = moves.get(method_name).get("class_id")
	#Se il percorso della mossa non termina con una classe, non succede nulla
	if class_id == "empty":
		return
	move_iterations = moves.get(method_name).get("iterations")
	
	var battle_move_path = str(Global.BATTLE_MOVES_FOLDER, class_id.capitalize().replace(" ", ""), "Move.tscn")
	var battle_move_scene = load(battle_move_path)
	battle_move_instance = battle_move_scene.instantiate()
	
	#Creiamo un timer per distanziare nel tempo le iterazioni della stessa mossa
	move_iterations_timer = Timer.new()
	move_iterations_timer.wait_time = 0.5
	move_iterations_timer.timeout.connect(_iterate_move)
	move_iterations_timer.one_shot = true
	add_child(move_iterations_timer)
	
	#Facciamo partire il primo colpo
	get_tree().get_nodes_in_group("player")[0].add_child(battle_move_instance.duplicate())
	move_iterations -= 1
	
	move_iterations_timer.start()

#Funzione invocata quando l'iteration timer raggiunge lo 0. Lancia nuovamente la mossa finchè le iterazioni non raggiungono lo 0
func _iterate_move():
	if move_iterations < 1:
		move_iterations_timer.queue_free()
		return
	
	get_tree().get_nodes_in_group("player")[0].add_child(battle_move_instance.duplicate())
	move_iterations -= 1
	move_iterations_timer.start()


#FUNZIONI PROVVISORIE

func _generate_reward():
	reward = RandomNumberGenerator.new().randi_range(50, 150)
	$VictoryScreen/BottomText.text = str(reward, "\nCOINS")

func _give_reward():
	if character.has_node("HealthComponent"):
		Global.game_player_hp = character.get_node("HealthComponent").get_hp()
	Global.game_money += reward

func _stop_battle():
	character.queue_free()
	enemy.queue_free()

func _on_map_button_pressed():
	Global.change_scene_to_map("battle", {"progress" : true})

func _on_game_over_button_pressed():
	Global.end_game()
	Global.change_scene_to_map("battle", {"level" : "test_level"})
