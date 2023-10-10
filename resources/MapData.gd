extends Resource
class_name MapData

@export var map_nodes : Dictionary = {}

func add_map_node(map_node_data : MapNodeData):
	map_nodes[str(map_node_data.id)] = map_node_data

func get_map_node_from_id(id : Vector2):
	return map_nodes.get(str(id))
