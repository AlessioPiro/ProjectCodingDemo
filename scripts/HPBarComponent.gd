extends Sprite3D

@export_enum("init_by_stats_component") var initialization_mode = "init_by_stats_component"

@onready var type_texture = $SubViewport/TypeTexture 
@onready var type_shadow_texture = $SubViewport/TypeShadowTexture 
@onready var name_label = $SubViewport/NameLabel
@onready var hp_bar = $SubViewport/HPBar

var max_hp : int = 100
var starting_hp : int = 100
var element_name : String = ""
var element_type : String = "normal"
var element_category : String = "enemy"

# Called when the node enters the scene tree for the first time.
func _ready():
	_set_viewport()
	_graphic_init()
	_connect_signals()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _set_viewport():
	texture = $SubViewport.get_texture()


#Inizializza graficamente la HPBar
func _graphic_init():
	#Inizializzazione della barra degli HP
		hp_bar.max_value = max_hp
		hp_bar.value = starting_hp
		
		#Inizializzazione del nome
		name_label.text = element_name
		
		#Inizializzazione del tipo
		type_texture.texture = load(str(Global.TYPES_ICONS_FOLDER, element_type, "_icon.png"))
		type_shadow_texture.texture = load(str(Global.TYPES_ICONS_FOLDER, element_type, "_icon.png"))
		type_texture.modulate = Global.types_colors.get(element_type)

#Chiamata da uno StatsComponent. Funziona solo se la modalità di inizializzazione è "init_by_stats_component"
func init_by_stats_component(input_element_name, input_element_type, input_element_category, input_hp_max : int):
	if initialization_mode == "init_by_stats_component":
		
		max_hp = input_hp_max
		
		if !get_parent().is_in_group("player"):
			starting_hp = input_hp_max
		
		element_name = input_element_name
		element_type = input_element_type
		element_category = input_element_category
		if element_category == "character":
			element_category = "player"


func _connect_signals():
	var parent_instance_id = get_tree().get_nodes_in_group(element_category)[0].get_instance_id()
	var battle_element_signal_manager = Global.scene_signal_manager.get_battle_element_signal_manager(parent_instance_id)
	
	battle_element_signal_manager.hp_lowered.connect(receive_damage)
	battle_element_signal_manager.hp_recover.connect(receive_healing)


func receive_damage(value : int):
	var current_hp = hp_bar.value
	var hp_after_damage = current_hp - value
	if hp_after_damage < 0:
		hp_after_damage = 0
	
	hp_bar.value = hp_after_damage

func receive_healing(value : int):
	var current_hp = hp_bar.value
	var max_hp = hp_bar.max_value
	var hp_after_healing = current_hp + value
	if hp_after_healing > max_hp:
		hp_after_healing = max_hp
	
	hp_bar.value = hp_after_healing
