extends Area3D

@export var disabled_on_start = true 
var position_on_grid : Vector2 = Vector2(-1, -1) #row, column starting from top, left
var connected_node : Area3D = null
var parent_puzzle_piece = null
var puzzle_piece_connection_size = 0 #Grandezza del puzzle piece che può ospitare in tasselli
var puzzle_piece_connection_size_sx = 0
var puzzle_piece_connection_size_dx = 0

@onready var bg_sprite = $PuzzlePieceBGSprite
@onready var collider = $CollisionShape3D
@onready var animation_player = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	if disabled_on_start:
		disable_puzzle_slot()
	else:
		enable_puzzle_slot()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func enable_puzzle_slot():
	visible = true
	collider.disabled = false
	animation_player.play("glow")

func disable_puzzle_slot():
	visible = false
	collider.disabled = true
	animation_player.stop()

func inizialize_puzzle_slot(input_position : Vector2, node : Area3D):
	position_on_grid = input_position
	connected_node = node

func set_puzzle_slot_position(input_position : Vector2):
	position_on_grid = input_position

func set_connected_node(node : Area3D):
	connected_node = node
	parent_puzzle_piece.set_chained()

func set_puzzle_piece_connection_size(size_sx : int, size_dx : int):
	puzzle_piece_connection_size_sx = size_sx
	puzzle_piece_connection_size_dx = size_dx
	
	#Dato che entrambi calcolano il pezzo centrale, se sono entrambi maggiori di 0 è necessario levare il pezzo centrale
	if size_dx > 0 and size_sx > 0:
		puzzle_piece_connection_size = size_sx + size_dx - 1
	else:
		puzzle_piece_connection_size = size_sx + size_dx

func set_parent_puzzle_piece(piece : Area3D):
	parent_puzzle_piece = piece
