extends Control

@export var hp_label : Label
@export var atk_label : Label
@export var def_label : Label
@export var luk_label : Label
@export var continue_button : Button
@export var coins_label : Label

# Called when the node enters the scene tree for the first time.
func _ready():
	#Imposta il valore delle monete
	coins_label.text = str(Global.total_money)
	
	#Mostra le statistiche nel menù
	hp_label.text = str("HP: ", Global.player_hp)
	atk_label.text = str("ATK: ", Global.player_atk)
	def_label.text = str("DEF: ", Global.player_def)
	luk_label.text = str("LUK: ", Global.player_luk)
	
	if !Global.continue_game:
		continue_button.disabled = true
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_new_game_button_pressed():
	
	pass # Replace with function body.
