extends Node
class_name Move

#Tempo di ricarica della mossa in secondi
var time : int
#Dizionario che contiene i pezzi di puzzle della mossa
var pieces_register : Dictionary = {}
#Dizionario che contiene tutti i possibili percorsi "logici" della mossa
var paths_register = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func add_piece(id_piece : int, id_object : String, form : String, parent_piece : int, parent_slot_position : int):
	
	#Recuperiamo l'oggetto associato al pezzo di puzzle e creiamo l'array dei pezzi di puzzle "figli"
	var children_pieces = []
	var object
	if Global.is_code_piece(id_object):
		object = Global.get_code_piece_by_id(id_object)
		for i in object.num_connections:
			children_pieces.append(-1)
	
	else:
		object = Global.get_class_by_id(id_object)
	
	#Creiamo il nuovo pezzo e aggiungiamolo alla mossa
	var piece = {"object_id" : id_object, "form" : form, "children_pieces" : children_pieces, "parent_piece_id" : parent_piece}
	pieces_register[id_piece] = piece
	
	
	#Aggiungiamo questo pezzo ai children piece del padre (tranne se è il primo, in quanto il root piece non viene aggiunto al registro)
	if parent_piece != -1:
		var parent = pieces_register.get(parent_piece)
		var parent_children = parent.get("children_pieces")
		if parent_children.size() > parent_slot_position and parent_children[parent_slot_position] == -1:
			parent_children[parent_slot_position] = id_piece
		else:
			print ("ERROR: Incorrect index of children while uploading a new piece in the move")
	
	#Se il pezzo aggiunto è una classe, aggiorna il tempo di ricarica
	if !Global.is_code_piece(id_object):
		update_time()



func remove_piece(id_piece : int):
	var parent_id = pieces_register.get(id_piece).get("parent_piece_id")
	var is_code_piece = Global.is_code_piece(pieces_register.get(id_piece).get("object_id"))
	
	#Rimuovi il pezzo
	pieces_register.erase(id_piece)
	
	#Rimuovi l'id del pezzo dal padre (o meglio, sostituiscilo con -1 che indica uno slot vuoto)
	if parent_id != -1:
		var parent_children_array = pieces_register.get(parent_id).get("children_pieces")
		var removed_piece_index = parent_children_array.find(id_piece)
		if removed_piece_index > -1:
			parent_children_array[removed_piece_index] = -1
	
	#Se il pezzo rimosso è una classe, aggiorna il tempo di ricarica
	if !is_code_piece:
		update_time()

func get_piece_by_id(input_id):
	return pieces_register.get(input_id)

func get_first_piece():
	return pieces_register.values()[0]

func get_first_piece_key():
	return pieces_register.keys()[0]

func is_move_empty():
	return pieces_register.is_empty()

#Aggiorna il tempo di ricarica
func update_time():
	var move_time_classes = []
	for piece in pieces_register.values():
		if !Global.is_code_piece(piece.get("object_id")):
			var move_class = Global.get_class_by_id(piece.get("object_id"))
			move_time_classes.append(move_class.time)
	
	if move_time_classes.is_empty():
		time = 0
	else:
		time = move_time_classes.max()
	return time


func get_time():
	return time


func check_piece_for_create_description_path(path_index : int, piece_index : int):
	var next_path_key : int
	var next_piece_key : int
	
	#Se queste condizioni sono vere vuol dire che lo slot del pezzo precedente era vuoto e quindi il path si è concluso
	if path_index != -1 and piece_index == -1:
		return
	
	#Per iniziare recuperiamo il path che stiamo percorrendo
	var path
	#Se è la prima chiamata di questa funzione crea un nuovo path con indice 0, altrimenti lo recupera dal registro
	if path_index == -1:
		
		#Se alla prima chiamata il registro dei pezzi è completamente vuoto, inserisce un percorso di default e termina la creazione del paths_register
		if pieces_register.is_empty():
			paths_register[0] = {"type" : "empty", "class_id" : "empty", "iterations" : 1, "checked_types" : []}
			return
		
		piece_index = get_first_piece_key()
		path = {"type" : "empty", "class_id" : "empty", "iterations" : 1, "checked_types" : []}
		path_index = 0
		paths_register[path_index] = path
	else:
		path = paths_register.get(path_index)
	
	#Recuperiamo il pezzo che stiamo esaminando
	var piece = get_piece_by_id(piece_index)
	var object_id = piece.get("object_id")
	
	#Se il pezzo è una classe, allora aggiorna il "class_id" del path e termina il percorso 
	if !Global.is_code_piece(object_id):
		path["class_id"] = piece.get("object_id")
		return
	
	#Dato che da ora in poi siamo sicuri che il pezzo sia un code piece, importiamo il code_piece di riferimento
	var object = Global.get_code_piece_by_id(object_id)
	
	#Se è un for, moltiplica le ripetizioni per il valore del for
	if object.category == "for":
		path["iterations"] = path.get("iterations") * object.num_iterations
		next_piece_key = piece.get("children_pieces")[0]
		next_path_key = path_index
		check_piece_for_create_description_path(next_path_key, next_piece_key)
	
	#Se è un if o un else_if...
	elif object.category.contains("if"):
		#Se il percorso non ha già un tipo assegna il nuovo tipo, crea nuovi percorsi quanti sono gli slot dell'if -1 (uno è quello che stiamo percorrendo) e li percorre
		if path.get("type") == "empty":
			var path_duplicate
			var iterator = 0
			for children in piece.get("children_pieces"):
				var new_path
				if iterator == 0:
					new_path = path
					next_path_key = path_index
					path_duplicate = {"type" : path.get("type"), "class_id" : path.get("class_id"), "iterations" : path.get("iterations"), "checked_types" : path.get("checked_types").duplicate()}
				else:
					new_path = {"type" : path_duplicate.get("type"), "class_id" : path_duplicate.get("class_id"), "iterations" : path_duplicate.get("iterations"), "checked_types" : path_duplicate.get("checked_types").duplicate()}
					next_path_key = paths_register.size()
					paths_register[next_path_key] = new_path
				
				#Controlliamo che il tipo collegato non faccia parte dei checked types
				var path_type = "empty"
				if iterator != piece.get("children_pieces").size() - 1:
					path_type = object.types[iterator]
					if new_path.get("checked_types").has(path_type):
						iterator += 1
						paths_register.erase(next_path_key)
						continue
				
				
				#Aggiungiamo i tipi dell'if ai checked types
				for type in object.types:
					if !new_path.get("checked_types").has(type):
						new_path.get("checked_types").append(type)
				
				#Diamo il tipo al percorso appena creato (tranne per l'else)
				if iterator < object.types.size():
					new_path["type"] = object.types[iterator]
				next_piece_key = children
				
				iterator += 1
				
				#Se il nodo figlio è uguale a -1 vuol dire che lo slot non è occupato e quindi si può interrompere il percorso
				if children == -1:
					continue
				else:
					check_piece_for_create_description_path(next_path_key, next_piece_key)
		
		#Se il percorso ha già un tipo e l'if ha uno slot per quel tipo, il percorso continua solo su quello slot
		elif object.types.has(path.get("type")):
			next_path_key = path_index
			next_piece_key = piece.get("children_pieces")[object.types.find(path.get("type"))]
			check_piece_for_create_description_path(next_path_key, next_piece_key)
		
		#Se il path ha già un tipo e l'if non ha uno slot per quel tipo, il percorso continua solo sullo slot dell'else
		else:
			next_path_key = path_index
			next_piece_key = piece.get("children_pieces")[piece.get("children_pieces").size() - 1]
			check_piece_for_create_description_path(next_path_key, next_piece_key)

func get_paths_register():
	return paths_register

#Dato un tipo in input, restituisce un dizionario contenente l'id della classe, le iterazioni e il tempo della mossa
func get_move_info_by_type(input_type : String):
	
	#Selezioniamo il path in base al tipo dato in input
	var choosen_path = ""
	var empty_type_path
	for path in paths_register.values():
		if path.get("type") == input_type:
			choosen_path = path
			break
		elif path.get("type") == "empty":
			empty_type_path = path
	if typeof(choosen_path) == TYPE_STRING and choosen_path == "":
		choosen_path = empty_type_path
	
	#Restituiamo il dizionario contenente l'id della classe, le iterazioni e il tempo della mossa
	var move_information = {"class_id" : choosen_path.get("class_id"), "iterations" : choosen_path.get("iterations"), "reload_time" : time}
	return move_information
	


func inizialize_path_register():
	var default_path = {"type" : "empty", "class_id" : "empty", "iterations" : 1, "checked_types" : []}
	paths_register[0] = default_path
