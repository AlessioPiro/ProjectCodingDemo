extends Node3D

const map_save_file_name = "MapSave.tres"

@onready var node = preload("res://scenes/assets_map/MapNode.tscn")
@onready var path = preload("res://scenes/assets_map/MapPath.tscn")
var map = Array2D.new() #Array bidimensionale che contiene tutti i nodi che compongono la mappa

@export var map_columns : int = 5
@export var map_rows : int = 20

var rng = RandomNumberGenerator.new()

##Tipi di nodo e relative probabilità
@export var types = {"battle": 60, "lunas": 5, "treasure": 5, "unknown": 30} 
##Di quanto si riduce la probabilità dell'apparizione di un tipo di nodo dopo la sua comparsa
@export var type_probability_shifts = {"battle": 10, "lunas": 25, "treasure": 50, "unknown": 20} 

##La probabilità iniziale della comparsa di un nodo
@export var node_probability = 40 
##Aumento della probabilità ogni volta che un nodo non appare
@export var node_probability_increase = 10 
##Diminuzione della probabilità ogni volta che un nodo appare
@export var node_probability_decrease = 15 
##Range (colonne) di connessione fra nodi
@export var node_connection_range = 2

##La probabilità iniziale della comparsa di un percorso
@export var path_probability = 50 
##Aumento della probabilità ogni volta che un percorso non appare
@export var path_probability_increase = 15
##Diminuzione della probabilità ogni volta che un percorso appare
@export var path_probability_decrease = 15
#@export var distance = 2.2

var center_node_first_row_position : Vector2 = Vector2(0, 0)
##Area intorno ad un nodo. Gestisce lo spazio tra un nodo e l'altro.
@export var node_area : Vector2 = Vector2(2.5,4) 


#Variabili per la gestione dello swipe
var camera_motion_speed : float = 100.0
var camera_brake : float = 1
var swipe_force : float = 0
var camera_distance_from_node : float = 11
var limit_min_map_zone : float = center_node_first_row_position.y - camera_distance_from_node
var limit_max_map_zone : float = (node_area.y * map_rows) - (camera_distance_from_node * 2)
var swipe_forward = false
var swipe_backward = false
var max_swipe_force = 10000

var map_progress = false

# Called when the node enters the scene tree for the first time.
func _ready():
	#All'avvio di una nuova partita...
	if !Global.continue_game:
		#Si genera una nuova mappa
		generate_map()
		#Si assegna ad ogni nodo valori specifici a seconda del loro tipo
		_assign_values_to_node_based_on_their_type()
		#Si salvano i dati della nuova mappa in un file apposito
		_save_map_as_resource()#save_map_values()
		#Si comunica a Global che una nuova partita è iniziata
		Global.set_new_game()
	
	#Se invece c'è già una partita in corso...
	else:
		#Si carica la mappa dal file dalvato alla generazione
		map = _load_map_from_resource()#load_map_values()
		#Se la scena precedente ha comunicato che il giocatore può avanzare, viene aggiornata la mappa in modo che si possa accedere ad i nodi successivi (e aggiornando gli altri di conseguenza). Si salvano i nuovi dati nel file apposito
		if map_progress:
			map_progress = false
			proceed_to_the_next_node()
			_save_map_as_resource()#save_map_values()
	Global.map = map
	
	#Vengono generati i nodi "fisicamente" e mostrati così al giocatore
	_display_map()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Cambia posizione della camera
	if swipe_forward:
		_camera_move(delta, "up")
	elif swipe_backward:
		_camera_move(delta, "down")

#Funzione che permette di importare dati dalle scene precedenti. Viene chiamata dal SceneSwitcher (al momento è in Global)
func import_data_from_previous_scene(transfer_data : Dictionary):
	if transfer_data.has("progress"):
		map_progress = transfer_data.get("progress")
	if transfer_data.has("level"):
		Global.set_level_id(transfer_data.get("level")) 

#Funzione che si occupa di recuperare i path delle scene definite a tempo di compilazione
func load_nodes_paths() -> Dictionary:
	var nodes_paths = {}
	
	#Carica il path della SkinMap
	var level =  Global.get_current_level()
	var skin_map_path = str(Global.MAP_SKIN_FOLDER, level.get_map_skin_name(), ".tscn")
	nodes_paths["skin_map"] = skin_map_path
	
	return nodes_paths

#Funzione che si occupa di aggiungere all'albero i nodi definiti a tempo di compilazione e caricati dal loader in Global
func add_loaded_nodes_to_tree(loaded_nodes : Dictionary):
	if loaded_nodes.has("skin_map"):
		var skin_map = loaded_nodes.get("skin_map").instantiate()
		add_child(skin_map)

#Modifica la mappa in modo da permettere al giocatore di avanzare
func proceed_to_the_next_node():
	var previous_node_id = Global.map_node_movement_from
	var current_node_id = Global.map_node_movement_to
	
	var previous_node_id_x = int(previous_node_id.x)
	var previous_node_id_y = int(previous_node_id.y)
	var current_node_id_x = int(current_node_id.x)
	var current_node_id_y = int(current_node_id.y)
	
	
	var previous_node = map.get_value(previous_node_id_x, previous_node_id_y)
	var current_node = map.get_value(current_node_id_x, current_node_id_y)
	
	#Settiamo tutti i nodi precedentemente raggiungibili come non raggiungibili
	
	#Se siamo sulla riga 1... (le righe vanno da 0 a 19)
	if previous_node_id == Vector2(-1, -1):
		for i in map_columns:
			var map_node = map.get_value(0, i)
			if map_node.state == "reachable":
				map_node.set_state("unreachable")
	#Per tutte le altre righe...
	else:
		for node_id_y in previous_node.next_nodes:
			var map_node = map.get_value(current_node_id_x, node_id_y)
			map_node.set_state("unreachable")
	
	#Settiamo il nodo precedente come "traveled"
	if !previous_node_id == Vector2(-1, -1):
		previous_node.set_state("traveled")
	
	#Settiamo il nodo corrente come "current"
	current_node.set_state("current")
	
	#Settiamo i nodi raggiungibili da quello corrente come "reachable"
	for node_column in current_node.next_nodes:
		var map_node = map.get_value(current_node_id_x + 1, node_column)
		map_node.set_state("reachable")


#!!!IN DISUSO!!! Salva tutte le variabili dei nodi in un file
func save_map_values():
	#Variabili da salvare
	var flash_energy : int
	var state : String
	var type : String
	var max_flash : int
	var next_nodes : Array
	var id : Vector2
	
	var data = {}
	
	for columns_i in map_columns:
		for rows_i in map_rows:
			#Raccogliamo i valori del nodo
			flash_energy = map.get_value(rows_i, columns_i).flash_energy
			state = map.get_value(rows_i, columns_i).state
			type = map.get_value(rows_i, columns_i).type
			max_flash = map.get_value(rows_i, columns_i).max_flash
			next_nodes = map.get_value(rows_i, columns_i).next_nodes
			id = map.get_value(rows_i, columns_i).id
			data = {"flash_energy": flash_energy, "state": state, "type": type, "max_flash": max_flash, "next_nodes": next_nodes, "id": id}
			
			#Salviamo i dati in un file
			var path_file = str("res://temporary/", rows_i, "-", columns_i, ".txt")
			var file = FileAccess.open(path_file, FileAccess.WRITE)
			for i in data.size():
				file.store_line(str(data.keys()[i],":",data.values()[i],"\r"))
			file.close()

#!!!IN DISUSO!!! Crea un nuovo array2d e lo riempie con nodi a cui da i valori precedenti e lo restituisce
func load_map_values():
	var new_map : Array2D = Array2D.new()
	
	for columns_i in map_columns:
		for rows_i in map_rows:
			
			var path_file = str("res://temporary/", rows_i, "-", columns_i, ".txt")
			var file = FileAccess.open(path_file, FileAccess.READ)
			var data = {}
			
			for i in file.get_as_text().count(":"):
				var line = file.get_line()
				var key = line.split(":")[0]
				var value = line.split(":")[1]
				if value.is_valid_float():
					value = float(value)
				elif value.begins_with("["):
					var char = ""
					var counter = 0
					var array = []
					while(char != "]"):
						char = value.substr(counter, 1)
						if char.is_valid_int():
							array.append(int(char))
						counter += 1
					value = array
				elif value.begins_with("("):
					var str_array = value.trim_prefix("(").trim_suffix(")").split(",")
					value = Vector2(int(str_array[0]), int(str_array[1]))
				else:
					value = str(value)
				data[key] = value
			file.close()
			
			var map_node = load("res://scenes/assets_map/MapNode.tscn").instantiate()
			map_node.set_id(data.get("id"))
			map_node.set_flash_energy(data.get("flash_energy"))
			map_node.set_state(data.get("state"))
			map_node.set_type(data.get("type"))
			map_node.set_max_flash(data.get("max_flash"))
			map_node.set_next_nodes(data.get("next_nodes"))
			new_map.set_value(rows_i, columns_i, map_node)
			
			
	return new_map

#Salva la mappa come risorsa
func _save_map_as_resource():
	var map_data = MapData.new()
	for columns_i in map_columns:
		for rows_i in map_rows:
			var map_node_data = MapNodeData.new()
			map_node_data.set_map_node_data_based_on_map_node(map.get_value(rows_i, columns_i))
			map_data.add_map_node(map_node_data)
	
	ResourceSaver.save(map_data, str(Global.SAVE_FOLDER + map_save_file_name))

#Carica la mappa dalla risorsa salvata in precedenza
func _load_map_from_resource():
	var map_data = ResourceLoader.load(str(Global.SAVE_FOLDER + map_save_file_name)).duplicate(true)
	var new_map : Array2D = Array2D.new()
	
	for columns_i in map_columns:
		for rows_i in map_rows:
			var map_node = node.instantiate()
			map_node.set_from_map_node_data(map_data.get_map_node_from_id(Vector2(rows_i, columns_i)))
			new_map.set_value(rows_i, columns_i, map_node)
	
	return new_map





func _camera_move(delta, direction):
	
	var d = delta * camera_motion_speed * swipe_force / camera_brake
	if(d < 0.01):
		swipe_forward = false
		swipe_backward = false
		camera_brake = 1
	if (direction == "down"):
		$Camera3D.global_position.z += d
	else:
		$Camera3D.global_position.z -= d
	if (camera_brake < 2):
		camera_brake *= 1.02
	else:
		camera_brake *= 1.05
	
	if $Camera3D.global_position.z > limit_max_map_zone:
		$Camera3D.global_position.z = limit_max_map_zone
		d = 0.01
	
	if $Camera3D.global_position.z < limit_min_map_zone:
		$Camera3D.global_position.z = limit_min_map_zone
		d = 0.01

func _camera_move_backward(delta):
	pass

func _display_map():
	var distance_from_center_x = floori(map_columns/2)  
	var starting_position_x = center_node_first_row_position.x + (distance_from_center_x * node_area.x)
	var starting_position_z = center_node_first_row_position.y
	
	var position_x = starting_position_x
	var position_z = starting_position_z
	
	for i_rows in map_rows:
		for i_columns in map_columns:
			
			#Apparizione dei nodi
			var node : MapNode = map.get_value(i_rows, i_columns)
			node.position = Vector3(position_x, 0, position_z)
			self.add_child(node)
			
			#Apparizione dei percorsi
			var next_nodes = node.next_nodes
			for next_node_index in next_nodes.size():
				var new_path : MapPath = path.instantiate()
				
				new_path.set_nodes(map.get_value(i_rows, i_columns), map.get_value(i_rows + 1, next_nodes[next_node_index]))
				
				var start_node_position = Vector2(position_x, position_z)
				var end_node_start_position = position_x - (node_area.x * (next_nodes[next_node_index] - i_columns))
				var end_node_position = Vector2(end_node_start_position, position_z + node_area.y)
				
				
				#Se i due nodi da collegare sono sulla stessa colonna
				if (start_node_position.x == end_node_position.x):
					var direction = (end_node_position - start_node_position)
					var path_position = start_node_position
					new_path.position = Vector3(path_position.x, 0, path_position.y)
					new_path.scale.z = direction.y
					new_path.position.z += direction.y/2
				
				else: #Immagina un triangolo rettangolo che, come estremi dell'ipotenusa, ha il centro dei due nodi da connettere
					var direction_right = false #Posizione del nodo successivo rispetto al nodo preso in esame
					var distance_x = abs(end_node_position.x - start_node_position.x) #Base del triangolo
					var distance_z = node_area.y #Altezza del triangolo
					direction_right = end_node_position.x < start_node_position.x
					var path_lenght = sqrt(pow(distance_x, 2) + pow(distance_z, 2)) #Alternativa: (distance_x * distance_z) / 2 #Calcolo dell'ipotenusa, ovvero del percorso tra i due nodi
					var mid_point = (start_node_position + end_node_position) / 2.0 
					
					#Gestione dell'angolo del percorso
					var path_angle = atan2(distance_x, distance_z)
					
					if (direction_right):
						path_angle = -path_angle
					
					new_path.position = Vector3(mid_point.x , 0, mid_point.y)
					new_path.scale.z = path_lenght
					new_path.rotation.y = path_angle
					#print(str("Starting node: ", start_node_position, "// Ending node: ", end_node_position, "// Rotation: ", path_angle))
				
				add_child(new_path)
			
			position_x -= node_area.x
			
		position_x = starting_position_x
		position_z += node_area.y 


#////////////////////////////////////////////////////////////////////////////////////////////////////
#////////////////////////////////////////////////////////////////////////////////////////////////////
#////////////////////////////////////////////////////////////////////////////////////////////////////
#GENERAZIONE DELLA MAPPA


#Genera la mappa
func generate_map():
	#Controlli sul numero di righe e colonne (entrambe maggiori di 3 e numero di colonne dispari)
	if map_columns < 3:
		map_columns = 3
	if map_rows < 3:
		map_rows = 3
	if (map_columns % 2) == 0:
		map_columns += 1
	
	for i in map_rows:
		_generate_row(i, map_rows, map_columns)
	
	

#Genera una riga della mappa
func _generate_row(row_number, rows, columns):
	#Creazione della prima riga: Due o più shop in posizioni casuali
	if row_number == 0:
		var enabled = 0
		for i in columns:
			var new_node = node.instantiate()
			if _node_enabler():
				new_node.state = "reachable"
				enabled += 1
				new_node.type = "lunas"
			else:
				new_node.state = "disabled"
			new_node.id = Vector2(row_number, i)
			map.set_value (row_number, i, new_node)
		
		if enabled < 2:
			_generate_row(row_number, rows, columns) 
	
	
	#Creazione dell'ultima riga: Solo Boss Fight come nodo centrale della riga
	elif row_number == rows - 1:
		for i in columns:
			var new_node = node.instantiate()
			if i == (floor(columns / 2)):
				new_node.state = "unreachable"
				new_node.type = "boss"
			else:
				new_node.state = "disabled"
			new_node.id = Vector2(row_number, i)
			map.set_value (row_number, i, new_node)
		
	
	#Creazione dalla seconda alla penultima riga: Ogni nodo è seguito, sulla riga successiva, da un nodo che sia o sulla stessa colonna o su una colonna adiacente. Nella penultima riga, i tipi di nodo sono solo "shop"
	else:
		
		#Per ogni nodo attivo della riga precedente crea un array con le possibili posizioni per i nodi sulla riga attuale
		for i in columns:
			var examinated_node = map.get_value(row_number - 1, i)
			if examinated_node.state != "disabled":
				var connected_nodes_array_columns = []
				
				for i3 in node_connection_range:
					var connection_node_index = i - ((node_connection_range - 1) - i3)
					if (connection_node_index) > -1 and (connection_node_index) < columns:
						connected_nodes_array_columns.append(connection_node_index)
				for i3 in node_connection_range:
					var connection_node_index = i + i3
					if connection_node_index > -1 and connection_node_index < columns and i3 != 0:
						connected_nodes_array_columns.append(connection_node_index)
				
				
				#Generiamo i nodi
				var enabled = 0
				for i2 in connected_nodes_array_columns.size():
					var new_node = node.instantiate()
					if map.get_value(row_number, connected_nodes_array_columns[i2]) != null and map.get_value(row_number, connected_nodes_array_columns[i2]).state == "unreachable":
						_path_enabler(examinated_node, connected_nodes_array_columns[i2])
						enabled +=1
					else:
						if _node_enabler():
							new_node.state = "unreachable"
							_path_enabler(examinated_node, connected_nodes_array_columns[i2])
							enabled += 1
							if (row_number == rows - 2):
								new_node.type = "lunas"
							else:
								new_node.type = _random_type_node()
								_change_type_probabilities(new_node.type)
							new_node.id = Vector2(row_number, connected_nodes_array_columns[i2])
							map.set_value (row_number, connected_nodes_array_columns[i2], new_node)
						else:
							new_node.state = "disabled"
							new_node.id = Vector2(row_number, connected_nodes_array_columns[i2])
							map.set_value (row_number, connected_nodes_array_columns[i2], new_node)
							
				#Nel caso non abbia inserito alcun nodo adiacente a uno della riga precedente, ne forziamo l'inserimento  
				if (enabled == 0):
					var ran_num = rng.randi_range(0,node_connection_range)
					var new_node = node.instantiate()
					new_node.state = "unreachable"
					new_node.type = _random_type_node()
					while (connected_nodes_array_columns.size() - 1) < ran_num:
						ran_num = rng.randi_range(0,(ran_num - 1))
					new_node.id = Vector2(row_number, connected_nodes_array_columns[ran_num])
					map.set_value (row_number, connected_nodes_array_columns[ran_num], new_node)
					_path_enabler(examinated_node, connected_nodes_array_columns[ran_num])
					_decrese_node_probability()
				
				if examinated_node.next_nodes.is_empty():
					_choose_random_path(examinated_node, connected_nodes_array_columns, row_number)
					pass
					
		#Tutti i nodi che non sono stati neanche controllati vengono disabilitati
		for i in columns:
			if map.get_value(row_number, i) == null:
				var new_node = node.instantiate()
				new_node.id = Vector2(row_number, i)
				map.set_value (row_number, i, new_node)
		
		#Tutti i nodi della penultima riga puntano alla boss fight
		if row_number == rows - 2:
			for i in columns:
				if map.get_value(map_rows - 2, i).state != "disabled":
					map.get_value(map_rows - 2, i).next_nodes.append(floor(columns / 2))
		
		#Controllo di eventuali nodi che non sono stati collegati ai precedenti
		var active_nodes = [] #Indice della colonna dei nodi della riga corrente attivi
		var connected_nodes = [] #Indice della colonna dei nodi della riga corrente connessi ad un percorso con un nodo della riga precedente
		
		for i in columns:
			var current_row_node = map.get_value(row_number, i)
			var previous_row_node = map.get_value(row_number - 1, i)
			if current_row_node.state != "disabled":
				active_nodes.append(i)
			
			if previous_row_node.state != "disabled":
				for i2 in previous_row_node.next_nodes.size():
					if !connected_nodes.has(previous_row_node.next_nodes[i2]):
						connected_nodes.append(previous_row_node.next_nodes[i2])
		
		for i in active_nodes.size():
			var examinated_node = active_nodes[i]
			if !connected_nodes.has(examinated_node):
				#Aggiungi path in extremis
				var candidate_nodes = []
				#Controlla quali nodi della riga precedente nel range sono attivi e raccogli la loro colonna in un array
				for i2 in columns:
					if i2 > examinated_node - node_connection_range and i2 < examinated_node + node_connection_range and map.get_value(row_number - 1, i2).state != "disabled":
						candidate_nodes.append(i2)
				
				#Scegline uno randomicamente
				var ran_num = rng.randi_range(0,candidate_nodes.size()-1)
				#Genera il percorso
				map.get_value(row_number - 1, candidate_nodes[ran_num]).next_nodes.append(examinated_node)
				_decrease_path_probability()

#Funzione che fa comparire un percorso con una data probabilità
func _path_enabler(node, column):
	var random_number = rng.randi_range(1,100)
	if random_number <= path_probability:
		node.next_nodes.append(column)
		_decrease_path_probability()
	else:
		_increase_path_probability()

#Funzione che diminuisce la probabilità di comparsa di un percorso
func _decrease_path_probability():
	path_probability -= path_probability_decrease
	if path_probability < 5:
		path_probability = 5


#Funzione che aumenta la probabilità di comparsa di un percorso
func _increase_path_probability():
	path_probability += path_probability_increase
	if path_probability > 100:
		path_probability = 100

#Forza la comparsa di un percorso da un nodo che non ne ha
func _choose_random_path(node, connected_nodes_array_columns, row):
	var possible_paths = []
	for i in connected_nodes_array_columns.size():
		if map.get_value(row,connected_nodes_array_columns[i]).state != "disabled":
			possible_paths.append(connected_nodes_array_columns[i])
	var ran_num = rng.randi_range(0,possible_paths.size() - 1)
	node.next_nodes.append(possible_paths[ran_num])
	_decrease_path_probability()

#Funzione che fa comparire un nodo con una data probabilità
func _node_enabler():
	var random_number = rng.randi_range(1,100)
	if random_number <= node_probability:
		_decrese_node_probability()
		return true
	else:
		_increase_node_probability()
		return false


#Funzione che diminuisce la probabilità di comparsa di un nodo
func _decrese_node_probability():
	node_probability -= node_probability_decrease
	if node_probability < 5:
		node_probability = 5


#Funzione che aumenta la probabilità di comparsa di un nodo
func _increase_node_probability():
	node_probability += node_probability_increase
	if node_probability > 100:
		node_probability = 100


#Funzione che sceglie randomicamente un tipo di nodo
func _random_type_node():
	
	var battle_value = types.get("battle")
	var shop_value = battle_value + types.get("lunas")
	var treasure_value = shop_value + types.get("treasure")
	
	var random_number = rng.randi_range(1,100)
	
	if random_number < battle_value:
		return "battle"
	elif random_number < shop_value:
		return "lunas"
	elif random_number < treasure_value:
		return "treasure"
	else:
		return "unknown"


#Funzione che cambia le probabilità di uscita dei vari tipi di nodi a seconda dell'ultimo uscito
func _change_type_probabilities(chosen):
	var chosen_probability = types.get(chosen)
	var actual_shift = type_probability_shifts.get(chosen)
	var percent_balancer = 0
	
	if chosen_probability < actual_shift:
		actual_shift = chosen_probability
	
	for key in types.keys():
		if key == chosen:
			types[key] -= actual_shift
			
		else:
			types[key] += floor(actual_shift / (types.size() - 1))
		
		percent_balancer += types[key]
		
		#print(str(chosen, "///", key, ": ", types.get(key)))
	
	if percent_balancer != 100:
		types["battle"] += (100 - percent_balancer) + 1
	
	pass

#////////////////////////////////////////////////////////////////////////////////////////////////////
#////////////////////////////////////////////////////////////////////////////////////////////////////
#////////////////////////////////////////////////////////////////////////////////////////////////////

#ATTRIBUZIONE DELLE INFORMAZIONI SPECIFICHE AI NODI A SECONDA DEL LORO TIPO

##Variabile che stabilisce un range per la variazione randomica del livello di un nemico rispetto a quello ideale (deciso a seconda della riga del nodo)
@export var enemy_level_max_variation : int = 2

var all_level_enemies = []
var available_enemies = []

var all_level_unknown_events = []
var available_unknown_events = []


func _assign_values_to_node_based_on_their_type():
	for rows_i in map_rows:
		for columns_i in map_columns:
			#Per ogni nodo verifichiamo prima di tutto se non è disabled
			var node = map.get_value(rows_i, columns_i)
			if node.get_state() != "disabled":
				match node.get_type():
					"battle", "boss":
						_assign_enemy_to_battle_node(node)
						_assign_level_to_battle_node(node)
					"lunas":
						pass
					"unknown":
						_assign_event_to_unknown_node(node)
					"treasure":
						_assign_reward_to_treasure(node)
					

#Assegna un nemico ad un nodo "Battle"
func _assign_enemy_to_battle_node(map_node : MapNode):
	#Nel caso non lo avessimo ancora fatto, riempiamo un array con tutti i nemici disponibili per questo livello
	if all_level_enemies.is_empty():
		all_level_enemies = Global.get_current_level().get_enemies_ids()
		available_enemies = all_level_enemies.duplicate()
	
	#Se non ci sono più nemici unici che il giocatore può incontrare, riempiamo nuovamente l'array dei nemici disponibili
	if available_enemies.size() == 0:
		available_enemies = all_level_enemies.duplicate()
	
	#Scegliamo casualmente un nemico dall'array di quelli disponibili e cancelliamolo subito dopo in modo da non farlo più incontrare al giocatore durante questa partita
	var enemy_index = rng.randi_range(0, available_enemies.size() - 1)
	var choosen_enemy_id = available_enemies[enemy_index]
	available_enemies.remove_at(enemy_index)
	
	map_node.set_single_value_in_type_related_variables("enemy_id", choosen_enemy_id)

#Assegna il livello del nemico ad un nodo "Battle"
func _assign_level_to_battle_node(map_node : MapNode):
	
	#Recuperiamo il valore minimo e massimo dei livelli per questo livello
	var min_lv = Global.get_current_level().get_min_enemies_level()
	var max_lv = Global.get_current_level().get_max_enemies_level()
	
	#Per calcolare il livello del nemico è necessario prima di tutto fare una proporzione tra il livello e la riga del nodo
	var ideal_level = min_lv + floori(int(map_node.get_id().x + 1)/(map_rows/(max_lv - min_lv + 1)))
	
	#Calcoliamo ora il livello finale aggiungendo una piccola variazione randomica
	var is_positive = rng.randi() % 2 == 0
	var final_level
	var random_level_variation = rng.randi_range(0, enemy_level_max_variation)
	if is_positive:
		final_level = ideal_level + random_level_variation
	elif enemy_level_max_variation < min_lv:
		final_level = ideal_level - random_level_variation
	else:
		final_level = ideal_level
	
	map_node.set_single_value_in_type_related_variables("enemy_level", final_level)

#Assegna un unknown events ad un nodo "Unknown"
func _assign_event_to_unknown_node(map_node : MapNode):
	#Nel caso non lo avessimo ancora fatto, riempiamo un array con tutti gli eventi disponibili per questo livello
	if all_level_unknown_events.is_empty():
		all_level_unknown_events = Global.get_current_level().get_unknown_events_ids()
		available_unknown_events = all_level_unknown_events.duplicate()
	
	#Se non ci sono più eventi unici che il giocatore può incontrare, riempiamo nuovamente l'array degli eventi disponibili
	if available_unknown_events.size() == 0:
		available_unknown_events = all_level_unknown_events.duplicate()
	
	#Scegliamo casualmente un evento dall'array di quelli disponibili e cancelliamolo subito dopo in modo da non farlo più incontrare al giocatore durante questa partita
	var event_index = rng.randi_range(0, available_unknown_events.size() - 1)
	var choosen_event_id = available_unknown_events[event_index]
	available_unknown_events.remove_at(event_index)
	
	map_node.set_single_value_in_type_related_variables("unknown_event_id", choosen_event_id)

#Assegna un numero di monete ad un nodo "Treasure"
func _assign_reward_to_treasure(map_node : MapNode):
	
	var rng = RandomNumberGenerator.new()
	var number = rng.randi_range(50, 150)
	
	map_node.set_single_value_in_type_related_variables("coins_number", number)







#////////////////////////////////////////////////////////////////////////////////////////////////////
#////////////////////////////////////////////////////////////////////////////////////////////////////
#////////////////////////////////////////////////////////////////////////////////////////////////////



#Movimento della camera
func _on_input_component_swipe(swipe_direction, swipe_difference, time):
	if (swipe_direction == "up"):
		camera_brake = 1
		swipe_forward = true
		swipe_backward = false
	elif (swipe_direction == "down"):
		camera_brake = 1
		swipe_backward = true
		swipe_forward = false
	else:
		return
	swipe_force = abs(swipe_difference.y) / time
	if swipe_force > max_swipe_force:
		swipe_force = max_swipe_force
	elif swipe_force < -max_swipe_force:
		swipe_force = -max_swipe_force
	
	swipe_force /= max_swipe_force
