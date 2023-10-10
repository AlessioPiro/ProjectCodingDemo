extends MarginContainer

@onready var main_hp_bar = $PlayerHPBar
@onready var damage_hp_bar = $PlayerHPBarRetro
@onready var hp_label = $PlayerHPBar/PlayerHPBarLabel
@onready var animator = $HPBarAnimation

@export var idle_label_effect = ["center", "wave"]
@export var damage_label_effect = ["center", "shake rate=5 level=10", "color=red", "outline_color=black"]
@export var healing_label_effect = ["center", "shake rate=5 level=10", "color=white", "outline_color=black"]

var max_hp
var player_hp

var are_signal_connected = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Effettua la connessione dei segnali non appena viene caricato il giocatore
	if !get_tree().get_nodes_in_group("player").is_empty() and !are_signal_connected:
		are_signal_connected = true
		_connect_signals()

# Tutti i segnali necessari vengono collegati al BattleElementSignalManager
func _connect_signals():
	var parent_instance_id = get_tree().get_nodes_in_group("player")[0].get_instance_id()
	var battle_element_signal_manager = Global.scene_signal_manager.get_battle_element_signal_manager(parent_instance_id)
	
	battle_element_signal_manager.hp_lowered.connect(receive_damage)
	battle_element_signal_manager.hp_recover.connect(receive_healing)

#Inizializzazione della barra (Lanciata dalla BattleScene come per tutti i componenti dell'UI)
func inizialize_hp_bar():
	
	#Recuperiamo gli hp del giocatore e gli hp massimi da Global
	max_hp = Global.player_hp
	player_hp = Global.game_player_hp
	
	#Settiamo i valori massimi, minimi e attuali di entrambe le HPBar e aggiorniamo la label
	main_hp_bar.max_value = max_hp
	main_hp_bar.value = player_hp
	
	damage_hp_bar.max_value = max_hp
	damage_hp_bar.value = player_hp
	
	var label_effects_string = _from_array_to_string(idle_label_effect)
	hp_label.text = str(label_effects_string, player_hp)


func _from_array_to_string(array):
	var final_string = ""
	for array_element in array:
		final_string = str(final_string, "[", array_element, "]")
	return final_string



func receive_damage(damage_amount : int):
	#Prima di lanciare l'animazione, aggiorniamo tutti i keyframe
	var animation = animator.get_animation("on_damage")
	var track = animation.find_track("PlayerHPBarRetro:value", 0)
	animation.track_set_key_value(track, 0, player_hp)
	animation.track_set_key_value(track, 1, player_hp - damage_amount)
	
	player_hp -= damage_amount
	if player_hp < 0: player_hp = 0
	main_hp_bar.value = player_hp
	animator.play("on_damage")


func receive_healing(healing_amount : int):
	#Prima di lanciare l'animazione, aggiorniamo tutti i keyframe
	var animation = animator.get_animation("on_healing")
	var track_retro_bar = animation.find_track("PlayerHPBarRetro:value")
	var track_main_bar = animation.find_track("PlayerHPBar:value")
	
	animation.track_set_key_value(track_retro_bar, 0, player_hp)
	animation.track_set_key_value(track_retro_bar, 1, player_hp + healing_amount)
	
	animation.track_set_key_value(track_main_bar, 0, player_hp)
	animation.track_set_key_value(track_main_bar, 1, player_hp + healing_amount)
	
	player_hp += healing_amount
	if player_hp > max_hp: player_hp = max_hp
	animator.play("on_healing")






func _set_damage_text():
	var label_effects_string = _from_array_to_string(damage_label_effect)
	hp_label.text = str(label_effects_string, player_hp)

func _set_healing_text():
	var label_effects_string = _from_array_to_string(healing_label_effect)
	hp_label.text = str(label_effects_string, player_hp)

func _set_idle_text():
	var label_effects_string = _from_array_to_string(idle_label_effect)
	hp_label.text = str(label_effects_string, player_hp)
