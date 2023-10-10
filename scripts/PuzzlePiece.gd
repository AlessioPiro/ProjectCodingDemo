extends Area3D
class_name PuzzlePiece

#Variabili esportate
##Colori dei pezzi di puzzle derivanti da pezzi di codice
@export var code_pieces_colors = {"if" : Color("#ff8800"), "else_if" : Color("#ff8800"), "for" : Color("#993800")}
##Colori delle icone dei tipi sui pezzi di puzzle
@export var types_colors = {"fire" : Color("#ff0000"), "water" : Color("#0c71c3"), "grass" : Color("#00ea12"), "normal" : Color("#00c191"), "healing" : Color("#ffdd00") ,"support": Color("#ffdd00")}
##Colore del pezzo di puzzle radice
@export var root_color = Color("#ffffff")

#Riferimenti ai nodi del puzzle_piece
@onready var sx_piece = $SxPiece
@onready var central_piece = $CentralPiece
@onready var dx_piece = $DxPiece
@onready var sx_piece_puzzle_slot = $SxPiece/PuzzleSlot
@onready var central_piece_puzzle_slot = $CentralPiece/PuzzleSlot
@onready var dx_piece_puzzle_slot = $DxPiece/PuzzleSlot
@onready var collider = $CollisionShape3D


#Posizione e dimensione del collider a seconda della forma del pezzo di puzzle
var collider_sizes = {1 : Vector3(3.8, 3.8, 0.15), 2 : Vector3(7.6, 3.8, 0.15), 3 : Vector3(11.4, 3.8, 0.15)}
var collider_positions = {"c" : Vector3(0, -0.55, 0), "sx" : Vector3(-1.925, -0.55, 0), "dx" : Vector3(1.925, -0.55, 0)}

#Posizione in cui spostare i nodi a seconda del nuovo centro dell'oggetto (da cambiare solo per pezzi di grandezza 3 o superiore)
var center_position_x_offset = {"right" : -3.84, "center" : 0, "left" : 3.84}

#Percorsi per sprite e icone (prima o poi dovrò renderle delle costanti globali)
var code_pieces_icons_path = "res://assets/icons/code_piece_icons/"
var class_icons_path = "res://assets/icons/class_icons/"
var types_icons_path = "res://assets/icons/type_icons/"
var puzzle_pieces_sprites_path = "res://assets/ui/lunas_pc2_menu/pc2_puzzle_pieces_sprites/"


var object #Il pezzo di codice o la classe a cui è collegato il pezzo di puzzle
var is_code_piece : bool = false #Vero se l'oggetto è un pezzo di codice, falso se l'oggetto è una classe
var piece_activation_order = ["c","dx","sx"] #L'ordine in cui i pezzi si attivano a seconda del numero di tasselli
var active_pieces = [] #Array dei pezzi attivi. L'ordine dei pezzi è sempre: sinistra, centrale, destra (ovviamente quando attivi)
var state #dragged, chained, detachable, root
var pieces_position_on_grid = {} #row, column starting from top, left
var connected_to_slot = null #Riferimento allo slot alla quale è connesso il Puzzle Piece
var puzzle_slots
var grid_size
var overlapping_targets = []

var form
var default_forms = {1 : "center", 2 : "right", 3 : "center"}
var hook_piece : String = "center"

# Called when the node enters the scene tree for the first time.
func _ready():
	active_pieces.append(central_piece)
	puzzle_slots = {"sx" : sx_piece_puzzle_slot, "c" : central_piece_puzzle_slot, "dx" : dx_piece_puzzle_slot}
	for slot in puzzle_slots.values():
		slot.set_parent_puzzle_piece(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if overlapping_targets.size() > 0:
		_check_piece_form()


func _check_piece_form():
	#Solo se è nello stato dragged!
	if state == "dragged" and active_pieces.size() > 1:
		var final_target
		
		#Se l'oggetto era su più di uno slot, allora si vede quale di questi fosse il più vicino
		if overlapping_targets.size() > 1:
			var nearest_target_index = 0
			var for_iterator = 0
			var min_distance = null
			for target in overlapping_targets:
				var distance_from_package = target.global_position.distance_to(global_position)
				if min_distance == null or min_distance > distance_from_package:
					nearest_target_index = for_iterator
					min_distance = distance_from_package
				for_iterator += 1
			final_target = overlapping_targets[nearest_target_index]
		
		#Se l'oggetto era su un solo slot, la scelta del target è piuttosto semplice...
		else:
			final_target = overlapping_targets[0]
		
		var sx_free_space = final_target.puzzle_piece_connection_size_sx
		var dx_free_space = final_target.puzzle_piece_connection_size_dx
		
		#Calcoliamo se la posizione del pezzo è alla destra del centro dello slot o alla sua sinistra
		var is_on_right_side = final_target.global_position.z - global_position.z >= 0
		
		#Se il pezzo è formato da due parti...
		if active_pieces.size() == 2:
			if (!is_on_right_side and sx_free_space >= 2) or dx_free_space < 2:
				_update_piece_form("left")
			else:
				_update_piece_form("right")
		
		#Se il pezzo è formato da tre parti...
		if active_pieces.size() == 3:
			if dx_free_space < 2:
				_update_piece_form("right")
			elif sx_free_space < 2:
				_update_piece_form("left")
			else:
				_update_piece_form("center")


func _update_piece_form(new_form : String):
	if form == new_form:
		return
	
	if active_pieces.size() == 2:
		
		#Cambia i pezzi attivi
		if new_form == "left":
			_disable_piece("dx")
			_enable_piece("sx")
			hook_piece = "center"
		else:
			_disable_piece("sx")
			_enable_piece("dx")
			hook_piece = "center"
		
		#Inserisci le nuove informazioni nei pezzi corrispondenti
		var iterator = 0
		for piece in active_pieces:
			piece.get_node("Label3D").text = object.piece_texts[iterator]
			
			if object.types.size() > iterator:
				piece.get_node("TypeSprite").visible = true
				piece.get_node("TypeSprite").texture = load(str(types_icons_path, object.types[iterator], "_icon.png"))
				piece.get_node("TypeSprite").modulate = types_colors.get(object.types[iterator])
				
			else:
				piece.get_node("TypeSprite").visible = false
			
			
			iterator += 1
	
	
	elif active_pieces.size() == 3:
		if new_form == "left":
			sx_piece.get_node("PuzzlePieceBGSprite").texture = load(str(puzzle_pieces_sprites_path, "hook_hole_piece.png"))
			dx_piece.get_node("PuzzlePieceBGSprite").texture = load(str(puzzle_pieces_sprites_path, "hole_piece.png"))
			central_piece.get_node("PuzzlePieceBGSprite").texture = load(str(puzzle_pieces_sprites_path, "hole_piece.png"))
			hook_piece = "right"
			
		elif new_form == "right":
			sx_piece.get_node("PuzzlePieceBGSprite").texture = load(str(puzzle_pieces_sprites_path, "hole_piece.png"))
			dx_piece.get_node("PuzzlePieceBGSprite").texture = load(str(puzzle_pieces_sprites_path, "hook_hole_piece.png"))
			central_piece.get_node("PuzzlePieceBGSprite").texture = load(str(puzzle_pieces_sprites_path, "hole_piece.png"))
			hook_piece = "left"
			
		else:
			sx_piece.get_node("PuzzlePieceBGSprite").texture = load(str(puzzle_pieces_sprites_path, "hole_piece.png"))
			dx_piece.get_node("PuzzlePieceBGSprite").texture = load(str(puzzle_pieces_sprites_path, "hole_piece.png"))
			central_piece.get_node("PuzzlePieceBGSprite").texture = load(str(puzzle_pieces_sprites_path, "hook_hole_piece.png"))
			hook_piece = "center"
			
		for node in get_children():
				node.position.x += center_position_x_offset.get(new_form) - center_position_x_offset.get(form)
	
	
	
	form = new_form

#FUNZIONI DI INIZIALIZZAZIONE DEI PEZZI DI PUZZLE

#Inizializzazione del root node. Riceve in input le dimensioni della griglia e il nome del metodo da mostrare nella sua label
func set_root_puzzle_piece(input_grid_size : Vector2, method_name : String):
	set_state("root")
	grid_size = input_grid_size
	central_piece.get_node("PuzzlePieceBGSprite").modulate = root_color
	central_piece.get_node("PuzzlePieceBGSprite").texture = load(str(puzzle_pieces_sprites_path, "hole_piece.png"))
	central_piece.get_node("ObjectSprite").visible = false
	set_puzzle_piece_position(Vector2(0, floor(grid_size.y/2)))
	$DragAndDropObjectComponent.set_disabled()
	central_piece.get_node("Label3D").text = str("public void ", method_name,"()")
	hook_piece = "center"

#Inizializzazione di un pezzo di puzzle creatosi dallo spostamento di un oggetto nell'inventario mostrato nel menu PC2
func set_puzzle_piece_from_stored_object(input_is_code_piece : bool, object_id : String, input_grid_size : Vector2):
	grid_size = input_grid_size
	set_state("dragged")
	_set_puzzle_piece(input_is_code_piece, object_id)
	form = default_forms.get(active_pieces.size())

#Inizializzazione di un pezzo di puzzle quando viene caricato da una move
func set_puzzle_piece_from_move_loading(input_is_code_piece : bool, object_id : String, input_form : String, input_state : String, input_grid_size : Vector2):
	grid_size = input_grid_size
	set_state(input_state)
	_set_puzzle_piece(input_is_code_piece, object_id)
	form = default_forms.get(active_pieces.size())
	_update_piece_form(input_form)
	

func _set_puzzle_piece(input_is_code_piece : bool, object_id : String):
	is_code_piece = input_is_code_piece
	if is_code_piece:
		_set_code_piece(object_id)
	else:
		_set_class(object_id)

func _set_code_piece(object_id : String):
	object = Global.get_code_piece_by_id(object_id)
	var icon
	if object.category == "if" or object.category == "else_if":
		icon = load(str(code_pieces_icons_path, object.category, "_icon.png"))
	else:
		icon = load(str(code_pieces_icons_path, object_id, "_icon.png"))
	
	if object.num_connections > 1:
		_enable_piece(piece_activation_order[1])
	if object.num_connections > 2:
		_enable_piece(piece_activation_order[2])
	
	#Aggiungiamo l'icona al pezzo centrale
	central_piece.get_node("ObjectSprite").texture = icon
	
	#Cambiamo il colore di tutti i pezzi
	for piece in get_children():
		var piece_group = piece.get_groups()
		if !piece_group.is_empty() and piece_group[0].contains("piece"):
			piece.get_node("PuzzlePieceBGSprite").modulate = code_pieces_colors.get(object.category)

	var iterator : int = 0
	for piece in active_pieces:
	#Cambiamo lo sprite dei pezzi
		if piece == central_piece:
			piece.get_node("PuzzlePieceBGSprite").texture = load(str(puzzle_pieces_sprites_path, "hook_hole_piece.png"))
		else:
			piece.get_node("PuzzlePieceBGSprite").texture = load(str(puzzle_pieces_sprites_path, "hole_piece.png"))
	#Aggiungiamo i testi per ogni pezzo
		piece.get_node("Label3D").text = object.piece_texts[iterator]
	#Se l'array "types" del code_piece è diversa da 0, aggiungiamo le icone dei tipi ai pezzi
		if !object.types.is_empty() and iterator < object.types.size():
			piece.get_node("TypeSprite").visible = true
			piece.get_node("TypeSprite").texture = load(str(types_icons_path, object.types[iterator], "_icon.png"))
			piece.get_node("TypeSprite").modulate = types_colors.get(object.types[iterator])
		iterator += 1

func _set_class(object_id : String):
	object = Global.get_class_by_id(object_id)
	var icon = load(str(class_icons_path, object_id, "_icon.png"))
	
	#Aggiungiamo l'icona al pezzo centrale
	central_piece.get_node("ObjectSprite").texture = icon
	#Settiamo l'aspetto del pezzo centrale come "hook_piece"
	central_piece.get_node("PuzzlePieceBGSprite").texture = load(str(puzzle_pieces_sprites_path, "hook_piece.png"))
	#Coloriamo il pezzo
	var class_type = object.get_type()
	central_piece.get_node("PuzzlePieceBGSprite").modulate = types_colors.get(class_type)
	#Impostiamo il testo
	central_piece.get_node("Label3D").text = str(object.object_class_name.to_lower(), ".", object.method, ";")
	#Settiamo lo sprite del tipo 
	var texture_type_name = class_type
	if texture_type_name == "support":
		texture_type_name = "status"
	central_piece.get_node("TypeSprite").texture = load(str(types_icons_path, texture_type_name, "_icon.png"))
	central_piece.get_node("TypeSprite").modulate = Color.html("#80000000")



#FUNZIONI DI AGGIORNAMENTO DEI DATI DEI PEZZI DI PUZZLE

#Quando il pezzo di puzzle viene rilasciato sulla griglia...
func drop_puzzle_piece_on_grid(input_connected_slot : Area3D):
	set_state("detachable")
	set_puzzle_piece_position(input_connected_slot.position_on_grid)
	connected_to_slot = input_connected_slot



#Setta la posizione del pezzo di puzzle (e dei suoi eventuali slot per collegari altri pezzi) una volta che viene rilasciato sulla griglia
func set_puzzle_piece_position(input_position : Vector2):
	var sx_position
	var c_position
	var dx_position
	if hook_piece == "center":
		c_position = input_position
		sx_position = Vector2(input_position.x, input_position.y - 1)
		dx_position = Vector2(input_position.x, input_position.y + 1)
	elif hook_piece == "right":
		dx_position = input_position
		c_position = Vector2(input_position.x, input_position.y + 1)
		sx_position = Vector2(input_position.x, input_position.y + 2)
	elif hook_piece == "left":
		sx_position = input_position
		c_position = Vector2(input_position.x, input_position.y - 1)
		dx_position = Vector2(input_position.x, input_position.y - 2)
	
	pieces_position_on_grid = {"sx" : sx_position, "c" : c_position, "dx" : dx_position}
	
	sx_piece_puzzle_slot.set_puzzle_slot_position(Vector2(pieces_position_on_grid.get("sx").x + 1, pieces_position_on_grid.get("sx").y))
	central_piece_puzzle_slot.set_puzzle_slot_position(Vector2(pieces_position_on_grid.get("c").x + 1, pieces_position_on_grid.get("c").y))
	dx_piece_puzzle_slot.set_puzzle_slot_position(Vector2(pieces_position_on_grid.get("dx").x + 1, pieces_position_on_grid.get("dx").y))



#Rende visibile e attiva il collider di un pezzo di codice
func _enable_piece(piece_index : String):
	var piece
	
	match piece_index:
		"sx":
			piece = sx_piece
			active_pieces.push_front(piece)
		"c":
			#In teoria non ci dovrebbe mai essere bisogno di attivare l'elemento centrale dato che è sempre attivo
			return
		"dx":
			piece = dx_piece
			active_pieces.push_back(piece)
	
	piece.visible = true
	_update_collider()



func _disable_piece(piece_index : String):
	var piece
	var puzzle_slot
	
	match piece_index:
		"sx":
			piece = sx_piece
			puzzle_slot = sx_piece_puzzle_slot
		"c":
			#Disabilitare il pezzo centrale non ha alcun senso. Se si vuole eliminare del tutto il puzzle piece tanto vale agire sull'intera scena
			return
		"dx":
			piece = dx_piece
			puzzle_slot = dx_piece_puzzle_slot
	
	if active_pieces.has(piece):
		active_pieces.erase(piece)
	
	piece.visible = false
	_update_collider()
	puzzle_slot.visible = false
	puzzle_slot.get_node("CollisionShape3D").disabled = true


func _update_collider():
	if active_pieces.size() == 1:
		collider.shape.size = collider_sizes.get(1)
		collider.position = collider_positions.get("c")
	elif active_pieces.size() == 3:
		collider.shape.size = collider_sizes.get(3)
		collider.position = collider_positions.get("c")
	else:
		collider.shape.size = collider_sizes.get(2)
		if active_pieces.has(sx_piece):
			collider.position = collider_positions.get("sx")
		else:
			collider.position = collider_positions.get("dx")


func enable_puzzle_slots(puzzle_piece : Area3D):
	if (state == "chained" or state == "detachable" and is_code_piece) or state == "root":
		var puzzle_piece_size = puzzle_piece.active_pieces.size()
		var occupied_columns = []
		#Per ogni slot di questo pezzo...
		for active_piece in active_pieces:
			var slot = active_piece.get_node("PuzzleSlot")
			#Se lo slot ha un pezzo collegato
			if slot.connected_node != null:
				for piece in slot.connected_node.active_pieces:
					if piece.is_in_group("sx_piece"):
						occupied_columns.append(slot.connected_node.pieces_position_on_grid.get("sx").y) 
					elif piece.is_in_group("c_piece"):
						occupied_columns.append(slot.connected_node.pieces_position_on_grid.get("c").y) 
					elif piece.is_in_group("dx_piece"):
						occupied_columns.append(slot.connected_node.pieces_position_on_grid.get("dx").y)
		
		#Procediamo ad assegnare a ogni PuzzleSlot un valore numerico che indica il numero massimo di pezzi che un pezzo di puzzle può avere per entrare nello spazio messo a disposizione da quello slot
		for piece in active_pieces:
			var slot = piece.get_node("PuzzleSlot")
			var slot_position = slot.position_on_grid
			var puzzle_piece_connection_size_dx = 0
			var puzzle_piece_connection_size_sx = 0
			#Se la sua posizione è fuori dalla griglia non può ospitare pezzi
			if slot_position.x >= grid_size.x or slot_position.y >= grid_size.y or slot_position.y < 0:
				puzzle_piece_connection_size_dx = 0
				puzzle_piece_connection_size_sx = 0
			#Se la colonna dello slot fa parte dell'array delle colonne occupate, non può ospitare pezzi
			elif occupied_columns.has(slot_position.y):
				puzzle_piece_connection_size_dx = 0
				puzzle_piece_connection_size_sx = 0
			else:
				var free_consecutive_position_sx = 1
				var free_consecutive_position_dx = 1
				var iterator = 1
				
				#Controlliamo quanti slot disponibili a sinistra ci sono
				while(true):
					if !occupied_columns.has(slot_position.y - iterator) and slot_position.y - iterator >= 0:
						free_consecutive_position_sx += 1
						iterator += 1
					else:
						iterator = 1
						break
				
				#Controlliamo quanti slot disponibili a desta ci sono
				while(true):
					if !occupied_columns.has(slot_position.y + iterator) and slot_position.y + iterator < grid_size.y:
						free_consecutive_position_dx += 1
						iterator += 1
					else:
						iterator = 1
						break
				
				puzzle_piece_connection_size_sx = free_consecutive_position_sx
				puzzle_piece_connection_size_dx = free_consecutive_position_dx
			
			slot.set_puzzle_piece_connection_size(puzzle_piece_connection_size_sx, puzzle_piece_connection_size_dx)
			
		
		
		for piece in active_pieces:
			var puzzle_slot = piece.get_node("PuzzleSlot")
			if puzzle_slot.connected_node == null and puzzle_piece.active_pieces.size() <= puzzle_slot.puzzle_piece_connection_size:
				puzzle_slot.enable_puzzle_slot()


func disable_puzzle_slots():
	for piece in active_pieces:
		var puzzle_slot = piece.get_node("PuzzleSlot")
		puzzle_slot.disable_puzzle_slot()


func should_be_chained():
	var should_be_chained : bool = false
	for slot in puzzle_slots.values():
		if slot.connected_node != null:
			should_be_chained = true
	
	return should_be_chained

#SETTER

func set_state(new_state : String):
	if state == "root":
		return
	elif new_state == "chained":
		set_chained()
	else:
		state = new_state
		if !get_node("DragAndDropObjectComponent").is_enabled():
			get_node("DragAndDropObjectComponent").set_enabled()


func set_chained():
	if state == "root":
		return
	state = "chained"
	get_node("DragAndDropObjectComponent").set_disabled()


#FUNZIONI DEI SIGNAL

func _on_area_entered(area):
	if !overlapping_targets.has(area) and area.is_in_group("pc2_puzzle_slot") and !area.is_in_group("pc2_stored_slot"):
		overlapping_targets.append(area)


func _on_area_exited(area):
	if overlapping_targets.has(area):
		overlapping_targets.erase(area)
