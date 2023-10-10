extends Control

@onready var animation_player = $AnimationPlayer
@onready var main_text = $CenterContainer/VBoxContainer2/MainText
@onready var reward_text = $CenterContainer/VBoxContainer2/RewardText
@onready var double_button_answer_1_text = $CenterContainer/VBoxContainer/DoubleButtonsContainer/Answer1Button/Answer1
@onready var double_button_answer_2_text = $CenterContainer/VBoxContainer/DoubleButtonsContainer/Answer2Button/Answer2
@onready var single_button_container = $CenterContainer/VBoxContainer/SingleButtonContainer
@onready var double_buttons_container = $CenterContainer/VBoxContainer/DoubleButtonsContainer


var event #Risorsa Unknown Event passata dalla mappa
var consequence_text #Testo della conseguenza data dalla scelta del giocatore
var effects = {} #Effetti della scelta del giocatore

# Called when the node enters the scene tree for the first time.
func _ready():
	#Setta i testi della domanda e delle risposte
	_init_texts()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func import_data_from_previous_scene(transfer_data : Dictionary):
	if transfer_data.has("unknown_event_id"):
		var event_id = transfer_data.get("unknown_event_id")
		event = Global.get_unknown_event_by_id(event_id)
	else:
		event = Global.get_unknown_event_by_id("two_doors_left")

func _init_texts():
	main_text.text = event.get_question()
	double_button_answer_1_text.text = event.get_answer_1()
	double_button_answer_2_text.text = event.get_answer_2()

func _on_answer_1_button_pressed():
	on_answer(1)


func _on_answer_2_button_pressed():
	on_answer(2)


func on_answer(choice : int):
	var effects_texts
	if choice == 1:
		consequence_text = event.get_consequence_1()
		effects_texts = event.get_effects_1()
	else:
		consequence_text = event.get_consequence_2()
		effects_texts = event.get_effects_2()
	
	#Trasforma gli effetti ad forma testuale a un dizionario che ne renda la lettura più accessibile
	translate_effects(effects_texts)
	
	animation_player.play("on_positive_response")
	
	#Attiva effetti
	
	pass

func translate_effects(effects_text):
	for effect_text in effects_text:
		var effect_name = effect_text.get_slice("(", 0)
		var effect_attributes_string = effect_text.get_slice("(", 1).trim_suffix(")")
		var effect_attributes = effect_attributes_string.split(",", false)
		
		effects[effect_name] = effect_attributes

func update_text_box_on_answer():
	#Fai apparire il testo della conseguenza
	main_text.text = consequence_text
	reward_text.text = create_reward_text()
	reward_text.visible = true
	pass

func activate_effects():
	var iterator = 0
	for effect in effects.keys():
		
		#money+ e money-
		if effect.contains("money"):
			var amount
			if effects.values()[iterator][0] == "all":
				amount = Global.game_money
			else:
				amount = int(effects.values()[iterator][0])
			if effect.contains("+"):
				Global.game_money += amount
			else:
				Global.game_money -= amount
				if Global.game_money < 0:
					Global.game_money = 0
		
		#package+
		elif effect.contains("package"):
			Global.add_player_s_package(effects.values()[iterator][0], 0)
			Global.unlock_package_description(effects.values()[iterator][0])
		
		#code_piece+
		elif effect.contains("code_piece"):
			Global.add_player_s_code_piece(effects.values()[iterator][0], 0)
		
		#health+ e health-
		elif effect.contains("health"):
			var amount
			if effects.values()[iterator][0] == "all":
				amount = Global.player_hp
			else:
				amount = int(effects.values()[iterator][0])
			if effect.contains("+"):
				Global.game_player_hp += amount
				if Global.game_player_hp > Global.player_hp:
					Global.game_player_hp = Global.player_hp
			else:
				Global.game_player_hp -= amount
				if Global.game_player_hp <= 0:
					Global.game_player_hp = 1
		
		iterator += 1

func create_reward_text() -> String:
	var text = ""
	if effects.is_empty() or effects.has("empty") or effects == null:
		text = "Nothing happened."
	else:
		var iterator = 0
		for effect in effects.keys():
			if iterator > 0:
				text = str(text, " ")
			
			var phrase
			
			if effect.contains("+"):
				phrase = "You obtained[color=green]"
			elif effect.contains("-"):
				phrase  = "You lost[color=red]"
			
			if effect.contains("money"):
				phrase = str(phrase, " ", effects.values()[iterator][0], " ", "coins[/color].")
			elif effect.contains("package"):
				var package_name = Global.get_package_by_id(effects.values()[iterator][0]).package_name
				phrase = str(phrase, " ", package_name, " ", "package[/color].")
			elif effect.contains("code_pieces"):
				var code_piece_name = Global.get_code_piece_by_id(effects.values()[iterator][0]).code_piece_name
				phrase = str(phrase, " ", code_piece_name, " ", "code piece[/color].")
			elif effect.contains("health"):
				phrase = str(phrase, " ", effects.values()[iterator][0], " ", "HPs[/color].")
			
			text = str(text, phrase)
			
			iterator += 1
	text = str("[center]", text, "[/center]")
	return text

func _on_quit_button_pressed():
	var transfer_data = {}
	transfer_data["progress"] = true
	Global.change_scene_to_map("unknown", transfer_data)
