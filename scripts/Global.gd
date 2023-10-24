extends Node

#VARIABILI


#Impostazioni
var max_tap_time = 3 #Tempo massimo di pressione per la validità del tap
var language = "english"
var max_buff_debuff_level = 10


#Dizionari contenenti colori standard
var types_colors = {"fire" : Color("#ff0000"), "water" : Color("#0c71c3"), "grass" : Color("#00ea12"), "normal" : Color("#00c191"), "healing" : Color("#ffdd00") ,"support": Color("#ffdd00")}

#Percorsi di cartelle ricorrenti
const MAP_SKIN_FOLDER = "res://assets/game_objects/map_skins/"
const BATTLE_MOVES_FOLDER = "res://assets/game_objects/battle_moves/"
const SAVE_FOLDER = "res://temporary/"
const TYPES_ICONS_FOLDER = "res://assets/icons/type_icons/"


#Variabili per il caricamento degli oggetti di gioco
var classes_directory = "res://assets/game_objects/classes/txt"
var code_pieces_directory = "res://assets/game_objects/code_pieces/txt"
var packages_directory = "res://assets/game_objects/packages/txt"
var enemies_table_path = "res://assets/game_objects/enemies/EnemiesTable.json"
var playable_characters_table_path = "res://assets/game_objects/playable_characters/PlayableCharactersTable.json"
var levels_table_path = "res://assets/game_objects/levels/LevelsTable.json"
var unknown_events_table_path = "res://assets/game_objects/unknown_events/EventsTable.json"

var classes = {} #Dizionario contenente coppie chiave-valore composte da id della classe e oggetto Classe corrispondente
var code_pieces = {}
var packages = {}
var enemies_infos = {}
var playable_characters_infos = {}
var levels = {}
var unknown_events = {}

var code_pieces_by_rarity = {} #Dizionario che contiene coppie "rarità - array di id di pezzi di codice con tale rarità"
var packages_by_rarity = {} #Dizionario che contiene coppie "rarità - array di id di pacchetti con tale rarità"

#Dati di gioco generali 
var total_money : int = 10
var character_id : String = "test_player"

var player_hp : int = 50
var player_atk : int = 50
var player_def : int = 50
var player_luk : int = 50

var player_level = 50

var unlocked_packages = {}

var max_code_piece_in_moves_lv = 1
#Fumetti raccolti


#Dati partita
var continue_game : bool = false
var map : Array2D = Array2D.new()
var game_player_hp : int = 130
var game_money : int = 500

var player_code_pieces = [] #Contiene gli id dei code_pieces posseduti dal giocatore
var player_packages = []
var equipped_packages = []
var moves = {}

var level_id = "test"

var map_node_movement_from : Vector2 = Vector2(-1,-1)#Quando viene caricata la mappa, viene salvato l'id del nodo di partenza in modo da permettere un corretto aggiornamento della mappa successivamente. Se questo nodo è uguale a (-1, -1) allora la mappa è appena stata generata e il giocatore deve ancora scegliere il nodo di partenza
var map_node_movement_to : Vector2 #Quando viene cliccato un nodo della mappa raggiungibile viene salvato l'id del nodo cliccato in modo da permettere un corretto aggiornamento della mappa successivamente 


#SignalManager
var scene_signal_manager = null

#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////

#INIZIALIZZAZIONE DEL PROGRAMMA

func _ready():
	#Caricamento degli oggetti di gioco
	_upload_all_game_objects()
	#Inizializza le mosse
	_inizialize_moves()

func _process(delta):
	change_scene_process()



#Caricamento di tutti gli oggetti di gioco
func _upload_all_game_objects():
	_upload_all_classes()
	_upload_all_code_pieces()
	_upload_all_packages()
	_upload_all_enemies_info()
	_upload_all_playable_characters_info()
	_upload_all_levels()
	_upload_all_unknown_events()


func _upload_all_classes():
	var classes_array = convert_txts_directory_into_array_of_dictionaries(classes_directory, ";")
	
	for data in classes_array:
		var class_scene = Class.new()
		
		class_scene.set_class_using_strings(data.get("id"), data.get(str(language,"_name")), data.get(str(language, "_description")), 
		data.get("time"), data.get(str(language,"_method")), data.get("type"))
		
		classes[data.get("id")] = class_scene


func _upload_all_code_pieces():
	var code_pieces_array = convert_txts_directory_into_array_of_dictionaries(code_pieces_directory, "|")
	
	for data in code_pieces_array:
		
		var code_piece_scene = CodePiece.new()
		
		code_piece_scene.set_code_piece_using_strings(data.get("id"), data.get(str(language,"_name")), data.get("price"), data.get("rarity"), 
		data.get(str(language,"_description")), data.get("category"), data.get("piece_texts"), data.get("num_connections"), 
		data.get("types"), data.get("num_iterations"))
		
		code_pieces[data.get("id")] = code_piece_scene
		
		#Aggiunta al dizionario che organizza i pezzi di codice per rarità
		if !code_pieces_by_rarity.has(int(data.get("rarity"))):
			code_pieces_by_rarity[int(data.get("rarity"))] = []
		code_pieces_by_rarity[int(data.get("rarity"))].append(data.get("id"))


func _upload_all_packages():
	var packages_array = convert_txts_directory_into_array_of_dictionaries(packages_directory, ";")
	
	for data in packages_array:
		
		var package_scene = Package.new()
		
		package_scene.set_package_using_strings(data.get("id"), data.get(str(language, "_name")), data.get("price"), data.get("rarity"), 
		data.get(str(language, "_locked_description")), data.get(str(language, "_unlocked_description")), data.get("classes"), 
		data.get("is_locked"))
		
		packages[data.get("id")] = package_scene
		
		#Aggiunta al dizionario che organizza i pezzi di codice per rarità
		if !packages_by_rarity.has(int(data.get("rarity"))):
			packages_by_rarity[int(data.get("rarity"))] = []
		packages_by_rarity[int(data.get("rarity"))].append(data.get("id"))


func _upload_all_enemies_info():
	var json_dictionary = convert_json_into_dictionary(enemies_table_path)
	
	var iterator = 0
	for enemy in json_dictionary.values():
		var enemy_info_key = json_dictionary.keys()[iterator]
		
		var enemy_info = EnemyInfo.new()
		enemy_info.set_enemy_info(enemy_info_key, enemy.get(str(language, "_name")), enemy.get(str(language, "_description")), enemy.get("type"),
		enemy.get("hp"), enemy.get("atk"), enemy.get("def"), enemy.get("luk"))
		
		enemies_infos[enemy_info_key] = enemy_info
		
		iterator += 1


func _upload_all_playable_characters_info():
	var json_dictionary = convert_json_into_dictionary(playable_characters_table_path)
	
	var iterator = 0
	for pc in json_dictionary.values():
		var pc_info_key = json_dictionary.keys()[iterator]
		
		var pc_info = PlayableCharacterInfo.new()
		pc_info.set_playable_character_info(pc_info_key, pc.get(str(language, "_name")), pc.get(str(language, "_description")), pc.get("type"),
		pc.get("hp"), pc.get("atk"), pc.get("def"), pc.get("luk"), pc.get("agi"))
		
		playable_characters_infos[pc_info_key] = pc_info
		
		iterator += 1
		


func _upload_all_levels():
	var json_dictionary = convert_json_into_dictionary(levels_table_path)
	
	var iterator = 0
	for level_dictionary in json_dictionary.values():
		level_dictionary["id"] = json_dictionary.keys()[iterator]
		var level = Level.new()
		level.set_level_by_dictionary(level_dictionary)
		
		levels[level_dictionary.get("id")] = level
		
		iterator += 1


func _upload_all_unknown_events():
	var json_dictionary = convert_json_into_dictionary(unknown_events_table_path)
	var iterator = 0
	for unknown_event in json_dictionary.values():
		unknown_event["id"] = json_dictionary.keys()[iterator]
		var event = UnknownEvent.new()
		event.set_event_by_dictionary(unknown_event)
		
		unknown_events[unknown_event.get("id")] = event
		
		iterator += 1
	

#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////

#GESTIONE DELLA PARTITA

#Aggiorna i dati per una nuova partita
func set_new_game():
	continue_game = true
	set_player_stat()

#Setta le statistiche del giocatore in base al personaggio scelto e al livello
func set_player_stat():
	var st_calc = StatsCalculator.new()
	var stats_dictionary = st_calc.calculate_all_stats("character", character_id, player_level)
	
	player_hp = stats_dictionary.get("hp")
	game_player_hp = stats_dictionary.get("hp")
	player_atk = stats_dictionary.get("atk")
	player_def = stats_dictionary.get("def")
	player_luk = stats_dictionary.get("luk")

#Termina una partita
func end_game():
	continue_game = false
	map = null


#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////

#CAMBIO SCENA

var is_scene_loading : bool = false #Booleano che indica se in questo momento un Thread sta caricando una scena.
var is_node_loading : bool = false #Booleano che indica se in questo momento un Thread sta caricando un nodo della scena.
var loader_thread #Riferimento al thread che si occupa di caricare scene e nodi. Al momento si utilizza un solo thread alla volta (oltre al main).
var from_scene_node #Riferimento alla scena che stiamo abbandonando. Verrà eliminata nel processo.
var transfer_data #Dati che si desiderano trasferire da una scena ad un'altra.
var next_scene #Riferimento alla nuova scena. Inizialmente vuota, viene caricata nel processo.
var nodes_paths_to_load : Dictionary ={} #Dizionario dei percorsi dei nodi che devono essere caricati per completare la nuova scena.
var loaded_nodes : Dictionary = {} #Dizionario dei nodi caricati, i cui percorsi sono indicari nel dizionario nodes_paths_to_load
var temp_key #Valore temporaneo della chiave di un nodo. Viene utilizzato per riutilizzare la stessa chiave nel dizionario dei nodi caricati

#Funzione "process" del sistema del cambio scena. Viene chiamato dal _process() di Global per ogni frame (Sarà il process della Resource)
func change_scene_process():
	_on_finished_scene_loading()
	_on_finished_node_loading()

#Se il nodo della scena ha finito di caricare, viene aggiunto al dizionario loaded_nodes. Se il dizionario nodes_paths_to_load è vuoto vuol dire che non ci sono più nodi da caricare e vengono restituiti i nodi alla scena creata in modo che possano essere aggiunti all'albero. Altrimenti si procede a caricare l'oggetto successivo
func _on_finished_node_loading():
	if is_node_loading == true:
		if !loader_thread.is_alive():
			is_node_loading = false
			var packed_node = loader_thread.wait_to_finish()
			loaded_nodes[temp_key] = packed_node
			nodes_paths_to_load.erase(temp_key)
			
			if nodes_paths_to_load.is_empty():
				if next_scene.has_method("add_loaded_nodes_to_tree"):
					next_scene.add_loaded_nodes_to_tree(loaded_nodes.duplicate())
			else:
				_start_node_loading()

#Funzione che si occupa di caricare, usando un nuovo Thread, il prossimo nodo di una scena prelevandone il path dal dizionario nodes_paths_to_load
func _start_node_loading():
	var node_path = nodes_paths_to_load.values()[0]
	temp_key = nodes_paths_to_load.keys()[0]
	loader_thread = Thread.new()
	var callable = Callable(self, "_loading")
	callable = callable.bind(node_path)
	loader_thread.start(callable)
	is_node_loading = true

#Se la scena è stata caricata si procede ad eliminare la vecchia, a caricare i nodi necessari e ad aggiungerla all'albero
func _on_finished_scene_loading():
	if is_scene_loading == true:
		if !loader_thread.is_alive():
			is_scene_loading = false
			
			#Rimuoviamo la vecchia scena
			from_scene_node.queue_free()
			
			#Instanzia la nuova scene
			var packed_scene = loader_thread.wait_to_finish()
			next_scene = packed_scene.instantiate()
			
			#Passa i dati alla nuova scena
			if next_scene.has_method("import_data_from_previous_scene"):
				next_scene.import_data_from_previous_scene(transfer_data)
			transfer_data.clear()
			
			#Carichiamo gli oggetti aggiunti dalla scena a tempo di compilazione
			if next_scene.has_method("load_nodes_paths"):
				nodes_paths_to_load = next_scene.load_nodes_paths()
				if !nodes_paths_to_load.is_empty():
					_start_node_loading()
			
			#Inserisce la nuova scena nel tree
			get_tree().get_root().add_child(next_scene)
			
			TransitionScene.on_loading_finish()
			return

#Funzione che fa partire il cambio della scena della mappa ad una nuova scene di cui viene indicato il path
func change_scene_from_map(to_scene : String, data : Dictionary):
	#Salva momentaneamente i dati da trasferire alla scena successiva
	transfer_data = data.duplicate()
	#Rendi maiuscola la prima lettera della stringa
	var scene_name : String = to_scene.capitalize()
	#Uniscila alla parola "Scene.tscn"
	var path = str("res://scenes/", scene_name, "Scene.tscn")
	#Chiama il TransitionScene
	TransitionScene.change_scene_from_map(path, to_scene)
	
	var from_scene_node_name = "MapScene"
	
	_load_new_scene(path, from_scene_node_name)

#Funzione che fa partire il cambio della scena da una scena verso la mappa (Prima o poi dovrò generalizzare questo codice per far in modo che esista una funzione unica per il cambio scena che non convolga la mappa)
func change_scene_to_map(from_scene, data : Dictionary):
	#Salva momentaneamente i dati da trasferire alla scena successiva
	transfer_data = data.duplicate()
	TransitionScene.change_scene_to_map(from_scene)
	var path = "res://scenes/MapScene.tscn"
	
	var from_scene_node_name = str(from_scene.capitalize().replace(" ", ""), "Scene")
	
	_load_new_scene(path, from_scene_node_name)


#Funzione che crea un nuovo thread e fa partire il caricamento della nuova scena
func _load_new_scene(target : String, from_scene_node_name : String):
	loader_thread = Thread.new()
	var callable = Callable(self, "_loading")
	callable = callable.bind(target)
	from_scene_node = get_tree().get_root().get_node(from_scene_node_name)
	loader_thread.start(callable)
	is_scene_loading = true
	

#Funzione che (solitamente) viene eseguita su un thread separato dal principale e che si occupa di caricare risorse
func _loading(scene_path : String):
	var loader = ResourceLoader.load_threaded_request(scene_path)
	var load_progress = []
	
	while true:
		match ResourceLoader.load_threaded_get_status(scene_path, load_progress):
			0: #ERRORE: la risorsa non è valida
				print("ERROR: The resource is invalid")
			1: #Sta ancora caricando la risorsa
				print(load_progress)
				pass #Può essere usata per mostrare una barra di caricamento
			2: #ERRORE: Caricamento fallito
				print("ERROR: loading failure")
			3: #Ha completato il caricamento
				return ResourceLoader.load_threaded_get(scene_path)
			


#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////

#GESTIONE OGGETTI DI GIOCO

	#PEZZI DI CODICE

#Restituisce un array di pezzi di codice di una data rarità 
func get_code_pieces_by_rarity(rarity : int):
	var code_pieces_array  = []
	for id in code_pieces_by_rarity.get(rarity):
		code_pieces_array.append(code_pieces.get(id))
	return code_pieces_array

#Aggiunge un pezzo di codice a quelli posseduti dal giocatore
func add_player_s_code_piece (id : String, price : int):
	player_code_pieces.append(id)
	game_money -= price

#Rimuove un pezzo di codice a quelli posseduti dal giocatore
func delete_player_s_code_piece (index : int):
	player_code_pieces.remove_at(index)

func delete_player_s_code_piece_by_id(id : String):
	player_code_pieces.erase(id)

#Restituisce un pacchetto dato il suo id. Altrimenti restituisce null
func get_code_piece_by_id(id : String):
	return code_pieces.get(id)

func is_code_piece(object_id : String):
	return code_pieces.has(object_id) 

	#PACCHETTI

#Restituisce un array di pacchetti di una data rarità 
func get_packages_by_rarity(rarity : int):
	var packages_array = []
	for id in packages_by_rarity.get(rarity):
		packages_array.append(packages.get(id))
	return packages_array

#Aggiunge un pacchetto a quelli posseduti dal giocatore
func add_player_s_package (id : String, price : int):
	player_packages.append(id)
	game_money -= price

#Rimuove un pacchetto a quelli posseduti dal giocatore restituendo se il pacchetto fosse equipaggiato o meno
func remove_player_package (id : String):
	if player_packages.has(id):
		player_packages.erase(id)
		return false
	elif equipped_packages.has(id):
		equipped_packages.erase(id)
		return true
	return null

#Sblocca la descrizione di un pacchetto
func unlock_package_description(input_id : String):
	if !unlocked_packages.has(input_id):
		unlocked_packages[input_id] = true
		return true
	return false

#Restituisce un pacchetto dato il suo id. Altrimenti restituisce null
func get_package_by_id(id : String):
	return packages.get(id)

#Equipaggia un pacchetto
func equip_package(id : String):
	player_packages.erase(id)
	equipped_packages.append(id)

#Disequipaggia un pacchetto
func unequip_package(id : String):
	equipped_packages.erase(id)
	player_packages.append(id)
	


	#CLASSI

#Restituisce una classe dato il suo id
func get_class_by_id(id : String):
	return Global.classes.get(id)


#Restituisce un array id delle classi del giocatore
func get_player_classes_ids():
	var player_classes = []
	for package_id in equipped_packages:
		for class_id in get_package_by_id(package_id).classes:
			if !player_classes.has(class_id):
				player_classes.append(class_id) 
	return player_classes


#Restituisce un array delle classi del giocatore
func get_player_classes():
	var player_classes = []
	for package_id in equipped_packages:
		for class_id in get_package_by_id(package_id).classes:
			if !player_classes.has(get_class_by_id(class_id)):
				player_classes.append(get_class_by_id(class_id)) 
	return player_classes



#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////

#GESTIONE MOSSE

#Riempie l'array delle mosse con 3 mosse (il costruttore, la prima mossa e la seconda mossa)
func _inizialize_moves():
	var constructor = Move.new()
	constructor.inizialize_path_register()
	var move1 = Move.new()
	move1.inizialize_path_register()
	var move2 = Move.new()
	move2.inizialize_path_register()
	
	moves = {"constructor" : constructor, "move1" : move1, "move2" : move2}


func get_move(move_name : String):
	return moves.get(move_name)


#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////

#GESTIONE LIVELLI

func get_current_level():
	return levels.get(level_id)

func get_current_level_id():
	return level_id

func set_level_id(new_level : String):
	level_id = new_level

#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////

#GESTIONE EVENTI

func get_unknown_event_by_id(id : String):
	return unknown_events.get(id)

#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////


#FUNZIONI GLOBALI

#Legge il contenuto di file txt di una directory indicata in input e restituisce un array contenente dizionari che contengono i dati dei file txt (txt -> dictionary) 
func convert_txts_directory_into_array_of_dictionaries(directory_path : String, divider : String):
	var dir = DirAccess.open(directory_path)
	dir.list_dir_begin()
	var objects_array = []
	
	while true:
		
		var txt_file = dir.get_next()
		if txt_file == "template.txt":
			continue
		if txt_file == "":
			break
		
		var data = {}
		var path_file = str(directory_path,"/",txt_file)
		var file = FileAccess.open(path_file, FileAccess.READ)
		
		#Lettura del file .txt
		for i in file.get_as_text().count(divider):
				var line = file.get_line()
				var key = line.get_slice(divider,0)
				var value = line.get_slice(divider,1)
				value = str(value)
				data[key] = value
		file.close()
		
		objects_array.append(data)
	
	dir.list_dir_end()
	return objects_array


#Legge il contenuto di un file JSON e lo inserisce in un dizionario
func convert_json_into_dictionary(file_path : String):
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var parsed_result = JSON.parse_string(file.get_as_text())
		
		if parsed_result is Dictionary:
			return parsed_result
		else:
			print("Error: JSON file (", file_path, ") converted in the wrong format!")
	
	else:
		print("Error: JSON file (", file_path, ") not found")
