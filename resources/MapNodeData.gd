extends Resource
class_name MapNodeData

@export var id : Vector2
@export var state : String
@export var type : String
@export var next_nodes : Array
@export var type_related_variables : Dictionary

func set_map_node_data(input_id : Vector2, input_state : String, input_type : String, input_next_nodes : Array, input_type_related_variables : Dictionary):
	id = input_id
	state = input_state
	type = input_type
	next_nodes = input_next_nodes
	type_related_variables = input_type_related_variables

func set_map_node_data_based_on_map_node(map_node : MapNode):
	id = map_node.get_id()
	state = map_node.get_state()
	type = map_node.get_type()
	next_nodes = map_node.get_next_nodes()
	type_related_variables = map_node.get_type_related_variables()

func get_id():
	return id

func get_state():
	return state

func get_type():
	return type

func get_next_nodes():
	return next_nodes

func get_type_related_variables():
	return type_related_variables
