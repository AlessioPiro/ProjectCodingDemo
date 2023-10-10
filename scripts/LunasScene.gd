extends Node3D

#Variabili Vending Machine
##Percentuale di variazione del prezzo di un prodotto nello shop
@export var shop_price_variable_min : int = 5
##Percentuale di variazione del prezzo di un prodotto nello shop
@export var shop_price_variable_max : int = 20
##Limite di pezzi di codice per categoria (DA IMPLEMENTARE IN FUTURO)
@export var limit_piece_category : int = 2
##Percentuale di uscita di pezzi di una determinata rarità
@export var rarity_pieces_possibility = {1 : 40, 2 : 30, 3 : 20, 4 : 8, 5 : 2}
##Numero di pezzi di codice presenti nella vending machine
@export var num_shop_code_pieces : int = 2
##Numero di pacchetti presenti nella vending machine
@export var num_shop_packages : int = 4

#Variabili Riposo
##Quantità di PS da ripristinare con l'uso del riposo
@export var starting_hp_rest = 20
##Percentuale di cambiamento dei PS ripristinati
@export var hp_rest_variable = 30
##Costo del riposo
@export var starting_rest_price = 120
##Percentuale di variazione del costo dedl riposo
@export var rest_price_variable = 30


var shop_code_pieces = []
var shop_packages = []
var shop_code_pieces_prices = []
var shop_packages_prices = []

var hp_rest : int = 0
var rest_price : int = 0

var state : String 
#SPIEGAZIONE STATI:
#1: moving_camera_from_*_to_# // indica che la camera attiva è quella del Luna's e che si sta muovendo da un luogo ad un altro.
#2: on_* // visualizzazione del menu *


@onready var anim_player = $"AnimationPlayer"

@onready var lunas_camera : Camera3D = $"LunasCameraPath/PathFollow3D/LunasCamera"
@onready var main_menu_camera : Camera3D = $"MainMenu/MainMenuCamera"
@onready var shop_menu_camera : Camera3D = $"ShopMenu/ShopMenuCamera"
@onready var bench_menu_camera : Camera3D = $"BenchMenu/BenchMenuCamera"
@onready var pc1_menu_camera : Camera3D = $"PC1Menu/PcCameraPath/PathFollow3D/PC1MenuCamera"

var cameras : Dictionary

@onready var lunas_camera_path = $LunasCameraPath

# Called when the node enters the scene tree for the first time.
func _ready():
	_initialize_shop()
	_initialize_rest()
	inizialize_pc1()
	_inizialize_pc2()
	
	anim_player.play("start")
	state = "moving_camera_to_main_menu"
	
	cameras = {"lunas_camera" : lunas_camera, "main_menu_camera" : main_menu_camera, "shop_menu_camera" : shop_menu_camera, "bench_menu_camera" : bench_menu_camera, "pc1_menu_camera" : pc1_menu_camera}
	lunas_camera_path.reset_path()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_pc1()


#FUNZIONI GENERALI DEL LUNAS

#Chiamata quando gli hp vengono modificati. Aggiorna tutte le informazioni in merito agli HP in tutti i menù
func _on_hp_change():
	_update_bench_menu_on_hp_change()
	_update_pc1_menu_on_hp_change()

#Chiamata quando il saldo viene modificato. Aggiorna tutte le informazioni in merito al saldo in tutti i menù
func _on_money_change():
	#Aggiorna il display dei soldi e lo stato dei prodotti nello Shop Menu
	_update_shop_menu_on_money_change()
	#Aggiorna il saldo nel Bench Menu
	_update_bench_menu_on_money_change()
	#Aggiorna i pacchetti presenti nel menu PC1
	_update_pc1_menu_on_money_change()
	







#SHOP

#Variabili dello Shop

#Stato dello shop
var shop_state : String = ""
#Prodotto selezionato
var shop_selected_product_index : int = -1 #Indice del prodotto selezionato (da 0 a 5). Se nessun prodotto è selezionato allora -1
#Lista di riferimenti ai nodi "Product" del menù Shop
var shop_products = []
#Riferimento all'Information Display
@onready var inf_display_name_label = $ShopMenu/vending_machine/InformationViewport/ProductNameLabel
@onready var inf_display_description_label = $ShopMenu/vending_machine/InformationViewport/ProductDescriptionLabel
#Riferimento al Money Display
@onready var money_display_moneys_label = $ShopMenu/vending_machine/MoneyViewport/PlayerMoneysLabel
#Riferimento al pulsante Buy
@onready var buy_button = $ShopMenu/BuyButton 
#Stato del pulsante Buy (enabled, disabled)
var buy_button_state : String = "enabled"

func _initialize_shop():
	_choose_shop_products()
	_set_shop_products()
	_reset_information_display()
	_update_money_display_on_charge()
	_update_buy_button_state()

func _update_shop_menu_on_money_change():
	_update_money_display_on_charge()
	_update_all_products_affordability()


#Sceglie quali prodotti mostrare nello shop e a che prezzo (NOTA: Non posso uscire due pacchetti o due pezzi uguali nello stesso shop)
func _choose_shop_products():
	for i in num_shop_code_pieces:
		while(true):
			var code_piece = _choose_shop_code_piece()
			if shop_code_pieces.find(code_piece) == -1:
				shop_code_pieces.append(code_piece)
				var price = _choose_price(code_piece.price)
				shop_code_pieces_prices.append(price)
				break
	
	for i in num_shop_packages:
		while(true):
			var package = _choose_shop_package()
			if shop_packages.find(package) == -1:
				shop_packages.append(package)
				var price = _choose_price(package.price)
				shop_packages_prices.append(price)
				break

#Restituisce un pezzo di codice casuale
func _choose_shop_code_piece():
	var rarity = _choose_rarity()
	var code_pieces_by_rarity : Array = Global.get_code_pieces_by_rarity(rarity)
	var rng = RandomNumberGenerator.new()
	var rnd_num = rng.randi_range(0, code_pieces_by_rarity.size() - 1)
	return code_pieces_by_rarity[rnd_num]

#Restituisce un pacchetto casuale
func _choose_shop_package():
	var rarity = _choose_rarity()
	var packages_by_rarity : Array = Global.get_packages_by_rarity(rarity)
	var rng = RandomNumberGenerator.new()
	var rnd_num = rng.randi_range(0, packages_by_rarity.size() - 1)
	return packages_by_rarity[rnd_num]

#Seleziona una rarità randomicamente
func _choose_rarity():
	var rng = RandomNumberGenerator.new()
	var rnd_num = rng.randi_range(1, 100)
	var percentage = 0
	
	for i in rarity_pieces_possibility.size():
		percentage += rarity_pieces_possibility.get(i+1)
		if rnd_num <= percentage:
			var rarity = i+1
			
			#SOLO PER LA DEMO
			if rarity > 3:
				rarity = 3
			
			return rarity

#Alza o abbassa il prezzo di un prodotto per delle percentuale predefinite
func _choose_price(price : int):
	var rng = RandomNumberGenerator.new()
	var percentage = rng.randi_range(shop_price_variable_min, shop_price_variable_max)
	var is_on_sale = rng.randi_range(0,1)
	var amount_variable = int(round(price * percentage / 100))
	var final_price
	if is_on_sale == 0:
		final_price = price + amount_variable
	else:
		final_price = price - amount_variable
	return final_price

#Riempie la Vending Machine
func _set_shop_products():
	var pieces_counter = 0
	var packages_counter = 0
	var lunas_machine = $"Luna's/vending_machine"
	var shop_menu_machine = $"ShopMenu/vending_machine"
	
	#Riempie la Vending Machine all'interno del Luna's
	for i in lunas_machine.get_children():
		if i.is_in_group("products"):
			if pieces_counter < num_shop_code_pieces:
				i.set_product(shop_code_pieces[pieces_counter], shop_code_pieces_prices[pieces_counter], pieces_counter)
				pieces_counter += 1
			else:
				i.set_product(shop_packages[packages_counter], shop_packages_prices[packages_counter], packages_counter + pieces_counter)
				packages_counter += 1
	
	#Riempie la Vending Machine del menù dello shop
	pieces_counter = 0
	packages_counter = 0
	for i in shop_menu_machine.get_children():
		if i.is_in_group("products"):
			shop_products.append(i) #Approfittiamo del ciclo per salvare i riferimenti a tutti i prodotti del menù Shop
			if pieces_counter < num_shop_code_pieces:
				i.set_product(shop_code_pieces[pieces_counter], shop_code_pieces_prices[pieces_counter], pieces_counter)
				pieces_counter += 1
			else:
				i.set_product(shop_packages[packages_counter], shop_packages_prices[packages_counter], packages_counter + pieces_counter)
				packages_counter += 1

#Sostituisce il prodotto selezionato nel menu con quello appena toccato nel menu Shop
func _set_current_product(input_index : int):
	#Deseleziona il precedente prodotto
	if shop_selected_product_index != -1:
		_deselect_current_product()
	
	#Aggiorna l'index del prodotto selezionato
	shop_selected_product_index = input_index
	
	#Attiva l'alone di selezione intorno al nuovo prodotto
	shop_products[shop_selected_product_index].set_current()
	
	#Recupera il pezzo di codice/pacchetto corrispondente
	var product_instance = shop_products[shop_selected_product_index].product
	
	#Mostra sul display nome e descrizione del nuovo prodotto
	_update_information_display(product_instance)

#Deseleziona il prodotto precedentemente selezionato nel menu Shop
func _deselect_current_product():
	shop_products[shop_selected_product_index].deselect_current()
	_reset_information_display()
	shop_selected_product_index = -1

#Aggiorna il display delle informazioni della Vending Machine del menu Shop
func _update_information_display(product_instance):
	if product_instance.get("code_piece_name") != null:
		inf_display_name_label.text = product_instance.code_piece_name
		inf_display_description_label.text = product_instance.description
	else:
		inf_display_name_label.text = product_instance.package_name
		if !Global.unlocked_packages.has(product_instance.id):
			inf_display_description_label.text = product_instance.locked_description
		else:
			inf_display_description_label.text = product_instance.unlocked_description

#Il display delle informazioni dello shop non mostrerà alcuna informazione
func _reset_information_display():
	inf_display_name_label.text = ""
	inf_display_description_label.text = ""

#Aggiorna il numero relativo al credito del giocatore dopo una spesa
func _update_money_display_on_charge():
	money_display_moneys_label.text = str("$", Global.game_money)

func _update_buy_button_state():
	if shop_selected_product_index == -1:
		_disabled_buy_button()
		return
	
	var shop_product = shop_products[shop_selected_product_index]
	if shop_product.state == "sold_out" or shop_product.state == "too_expensive":
		_disabled_buy_button()
	else:
		_enable_buy_button()

func _disabled_buy_button():
	if buy_button_state == "enabled":
		buy_button_state = "disabled"
		buy_button.get_node("Sprite").modulate = Color(0.5, 0.5, 0.5)
		buy_button.get_node("ButtonComponent").set_disabled()


func _enable_buy_button():
	if buy_button_state == "disabled":
		buy_button_state = "enabled"
		buy_button.get_node("Sprite").modulate = Color("WHITE")
		buy_button.get_node("ButtonComponent").set_enabled()


func _shop_buy_selected_product():
	
	var is_code_piece = false
	var product
	
	#Individua il tipo di prodotto acquistato
	if shop_selected_product_index < num_shop_code_pieces:
		is_code_piece = true
		product = shop_code_pieces[shop_selected_product_index]
	else:
		product = shop_packages[shop_selected_product_index - num_shop_code_pieces]
	
	#Aggiunge l'oggetto all'inventario del giocatore e ne diminuisce i soldi
	if is_code_piece:
		Global.add_player_s_code_piece(product.id, shop_code_pieces_prices[shop_selected_product_index])
	else:
		Global.add_player_s_package(product.id, shop_packages_prices[shop_selected_product_index - num_shop_code_pieces])
	
	#Se non fosse già sbloccata, sblocca la descrizione completa del prodotto
	if !is_code_piece:
		_unlock_package_description(product.id)
	
	#Cambia lo stato del prodotto nello shop a "SOLD OUT"
	shop_products[shop_selected_product_index].set_sold_out()
	
	#Aggiorna tutti i menu con il nuovo saldo
	_on_money_change()
	
	#Aggiorna lo stato del pulsante buy
	_update_buy_button_state()
	
	pass

#Chiamato per aggiornare lo stato dei prodotti dopo una variazione di denaro
func _update_all_products_affordability():
	for i in shop_products:
		i.check_is_too_expensive()

#Controlla se la vera descrizione sia già stata sbloccata. Se così non fosse, la sblocca.
func _unlock_package_description(id : String):
	if Global.unlock_package_description(id):
		shop_products[shop_selected_product_index].product.is_locked = false
		_update_information_display(shop_products[shop_selected_product_index].product)


#///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#BENCH


#Variabili del Menu Bench
@onready var rest_price_label = $BenchMenu/RestButton/CostLabel
@onready var rest_hp_label = $BenchMenu/RestButton/HPLabel
@onready var hp_bar_label = $BenchMenu/HPBar/HPLabel
@onready var money_bar_label = $BenchMenu/MoneyBar/MoneyLabel
@onready var rest_button = $BenchMenu/RestButton
@onready var bench_menu_animation_player = $BenchMenu/BenchMenuAnimationPlayer

var rest_button_state = "active" #Possibili stati: active, too_expensive, already_used

func _initialize_rest():
	_choose_rest()
	_set_rest()
	_update_bench_menu_money()
	_update_bench_menu_hp()

func _update_bench_menu_on_hp_change():
	_update_bench_menu_hp()

func _update_bench_menu_on_money_change():
	_update_bench_menu_money()
	update_rest_button()




#Setta le scritte del menù Bench relative alla quantità di HP da recuperare e il costo del Riposo
func _set_rest():
	rest_price_label.text = str("-$",rest_price)
	rest_hp_label.text = str("+", hp_rest, " HP")

#Aggiorna il numero di soldi nella barra dedicata nel menù Bench
func _update_bench_menu_money():
	money_bar_label.text = str("$",Global.game_money)

#Aggiorna la label degli HP nella barra dedicata nel menù Bench
func _update_bench_menu_hp():
	hp_bar_label.text = str(Global.game_player_hp,"/",Global.player_hp)

#Cosa succede quando clicchi sul pulsante "Rest"?
func _rest():
	#Lancia Animazione (Area 3D davanti allo schermo per non consentire click sui pulsanti e consentire lo skip dell'animazione)
	#Idea animazione
	pass

#Setta gli HP e il prezzo del Riposo
func _choose_rest():
	hp_rest = _choose_rest_hp_amount()
	rest_price = _choose_rest_price()


#Decide il numero di HP recuperabile tramite il Rest
func _choose_rest_hp_amount():
	var final_hp_rest = 0
	var normal_amount = int(round(Global.player_hp * starting_hp_rest / 100))
	var rng = RandomNumberGenerator.new()
	var variance = rng.randi_range(0, hp_rest_variable)
	var variance_amount = int(round(normal_amount * variance / 100))
	var add_hp = rng.randi_range(0,1)
	if (add_hp == 1):
		final_hp_rest = normal_amount + variance_amount
	else:
		final_hp_rest = normal_amount - variance_amount
	return final_hp_rest


#Decide il costo del Rest
func _choose_rest_price():
	var final_price = 0
	var rng = RandomNumberGenerator.new()
	var variance = rng.randi_range(0, rest_price_variable)
	var variance_amount = int(round(starting_rest_price / 100 * variance))
	var add = rng.randi_range(0,1)
	if (add == 1):
		final_price = starting_rest_price + variance_amount
	else:
		final_price = starting_rest_price - variance_amount
	return final_price


#Controlla se lo stato del pulsante "Rest" va modificato e, se necessario, lo modifica
func update_rest_button():
	if rest_button_state == "already_used":
		return
	elif Global.game_money < rest_price and rest_button_state != "too_expensive":
		rest_button_state = "too_expensive"
		disabled_rest_button()
	elif rest_button_state != "active":
		rest_button_state = "active"
		enabled_rest_button()


#Gestisce la meccanica del "rest" al click del pulsante nel menù Bench del Lunas
func _on_rest():
	bench_menu_animation_player.play("rest")

#Chiamato dall'BenchMenuAnimationPlayer. Aumenta gli HP del giocatore di quanto stabilito
func _bench_rest_heal():
	Global.game_player_hp += hp_rest
	if Global.game_player_hp > Global.player_hp:
		Global.game_player_hp = Global.player_hp
	Global.game_money -= rest_price
	
	#Aggiorna il numero di HP e di soldi visualizzati da tutti i menu del Lunas
	_on_money_change()
	_on_hp_change()
	
	#Setta lo stato del pulsante su "already_used"
	rest_button_state = "on_already_used"
	disabled_rest_button()


#Disabilita il pulsante "Rest" nel menù Bench del Lunas
func disabled_rest_button():
	
	#Porta la saturazione del pulsante a 0
	for i in rest_button.get_children():
		if i.is_class("Sprite3D") or i.is_class("Label3D"):
			i.modulate = Color(i.modulate.h, 0, i.modulate.v, 1.0)
	
	#Disattiva il ButtonComponent per evitare ulteriori click
	rest_button.get_node("ButtonComponent").set_disabled()

#Attiva il pulsante "Rest" nel menù Bench del Lunas
func enabled_rest_button():
	#Restaura la saturazione originale del pulsante
	for i in rest_button.get_children():
		if i.is_class("Sprite3D") or i.is_class("Label3D"):
			i.modulate = Color("WHITE")
	
	#Riattiva il ButtonComponent
	rest_button.get_node("ButtonComponent").set_enabled()




#///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

# PC 1

#Variabili Label delle Statistiche
@onready var pc1_hp_label = $PC1Menu/CodingWindow/StatsLabels/HPLabel
@onready var pc1_max_hp_label = $PC1Menu/CodingWindow/StatsLabels/MaxHPLabel
@onready var pc1_atk_label = $PC1Menu/CodingWindow/StatsLabels/ATKLabel
@onready var pc1_def_label = $PC1Menu/CodingWindow/StatsLabels/DEFLabel
@onready var pc1_luk_label = $PC1Menu/CodingWindow/StatsLabels/LUKLabel

#Variabili della data e dell'orologio
@onready var pc1_time_label = $PC1Menu/Taskbar/Date/TimeLabel
@onready var pc1_date_label = $PC1Menu/Taskbar/Date/DateLabel

var pc1_package_scene = preload("res://scenes/assets_shop/PC1Package.tscn")
var packages_node : Node3D
var equipped_packages_node : Node3D

#Variabili per la gestione del drag and drop
var occupied_slots = {}

var starting_slot

func inizialize_pc1():
	_update_all_pc1_stats_label()
	_update_clock_and_date()
	_spawn_player_packages_in_pc1_menu()
	_spawn_equipped_packages_in_pc1_menu()

func process_pc1():
	_update_clock_and_date()

func _update_pc1_menu_on_hp_change():
	pc1_hp_label.text = str("private int HP = ", Global.game_player_hp ,";")

func _update_pc1_menu_on_money_change():
	#Elimina tutti i pacchetti
	_delete_player_packages_in_pc1_menu()
	#Reinserisci tutti i pacchetti
	_spawn_player_packages_in_pc1_menu()

func _update_all_pc1_stats_label():
	pc1_hp_label.text = str("private int HP = ", Global.game_player_hp ,";")
	pc1_max_hp_label.text = str("private int MaxHP = ", Global.player_hp ,";")
	pc1_atk_label.text = str("private int ATK = ", Global.player_atk ,";")
	pc1_def_label.text = str("private int DEF = ", Global.player_def ,";")
	pc1_luk_label.text = str("private int LUK = ", Global.player_luk ,";")

func _update_clock_and_date():
	pc1_time_label.text = Time.get_time_string_from_system().substr(0,5)
	pc1_date_label.text = Time.get_date_string_from_system()

func _spawn_equipped_packages_in_pc1_menu():
	var equipped_packages_ids = Global.equipped_packages
	
	var pc1_menu_node = $PC1Menu
	equipped_packages_node = Node3D.new()
	pc1_menu_node.add_child(equipped_packages_node)
	
	
	var equipped_packages_slots = $PC1Menu/CodingWindow/ImportPackagesSlots.get_children()
	var packages_slots_counter = 0
	
	for package_id in equipped_packages_ids:
		var pc1_package = pc1_package_scene.instantiate()
		pc1_package.set_pc1_package(package_id)
		equipped_packages_node.add_child(pc1_package)
		
		#La posizione del pacchetto è uguale a quella dello slot a cui dobbiamo togliere la sua global_position (data da tutti i nodi padre)
		pc1_package.position = equipped_packages_slots[packages_slots_counter].global_position - pc1_package.global_position
		pc1_package.rotation = equipped_packages_slots[packages_slots_counter].global_rotation
		pc1_package.scale = Vector3(0.19, 0.19, 0.19)
		
		#Connetti i segnali del DragAndDropObjectComponent
		if pc1_package.has_node("DragAndDropObjectComponent"):
			pc1_package.get_node("DragAndDropObjectComponent").on_drag_drag_and_drop_object.connect(_on_drag_drag_and_drop_object)
			pc1_package.get_node("DragAndDropObjectComponent").on_drop_drag_and_drop_object.connect(_on_drop_drag_and_drop_object)
			pc1_package.get_node("DragAndDropObjectComponent").on_button_pressed_drag_and_drop_object.connect(_on_button_pressed_drag_and_drop_object)
		
		#Aggiungi lo slot al dizionario degli slot occupati
		occupied_slots[str(equipped_packages_slots[packages_slots_counter].global_position)] = pc1_package
		
		packages_slots_counter += 1
	

func _spawn_player_packages_in_pc1_menu():
	var player_packages_ids = Global.player_packages
	
	var pc1_menu_node = $PC1Menu
	packages_node = Node3D.new()
	pc1_menu_node.add_child(packages_node)
	
	
	var player_packages_slots = $PC1Menu/PackagesWindow/PlayerPackagesSlot.get_children()
	var packages_slots_counter = 0
	
	for package_id in player_packages_ids:
		var pc1_package = pc1_package_scene.instantiate()
		pc1_package.set_pc1_package(package_id)
		packages_node.add_child(pc1_package)
		
		#La posizione del pacchetto è uguale a quella dello slot a cui dobbiamo togliere la sua global_position (data da tutti i nodi padre)
		pc1_package.position = player_packages_slots[packages_slots_counter].global_position - pc1_package.global_position
		pc1_package.rotation = player_packages_slots[packages_slots_counter].global_rotation
		pc1_package.scale = Vector3(0.19, 0.19, 0.19)
		
		
		#Connetti i segnali del DragAndDropObjectComponent
		if pc1_package.has_node("DragAndDropObjectComponent"):
			pc1_package.get_node("DragAndDropObjectComponent").on_drag_drag_and_drop_object.connect(_on_drag_drag_and_drop_object)
			pc1_package.get_node("DragAndDropObjectComponent").on_drop_drag_and_drop_object.connect(_on_drop_drag_and_drop_object)
			pc1_package.get_node("DragAndDropObjectComponent").on_button_pressed_drag_and_drop_object.connect(_on_button_pressed_drag_and_drop_object)
		
		#Aggiungi lo slot al dizionario degli slot occupati
		occupied_slots[str(player_packages_slots[packages_slots_counter].global_position)] = pc1_package
		
		packages_slots_counter += 1


func _delete_player_packages_in_pc1_menu():
	for package in packages_node.get_children():
		package.queue_free()

func _pc1_on_drag_object(object : Area3D, overlapping_targets : Array):
	starting_slot = overlapping_targets[0]

#Chiamato al momento del rilascio dell'oggetto
func _pc1_on_drop_object(object : Area3D, overlapping_targets : Array):
	
	var final_target #Variabile in cui si inserisce lo slot in cui verrà spostato il pacchetto
	
	#Puliamo l'array in input da tutte le aree rilevate che non siano slot (PS La duplicazione è necessaria in quanto rimuovere elementi da una array durante una sua iterazione può far saltare alcuni elementi dell'array stesso)
	var temp_overlapping_targets = overlapping_targets.duplicate()
	for area in overlapping_targets:
			if !area.is_in_group("pc1_package_slot"):
				temp_overlapping_targets.erase(area) 
	overlapping_targets = temp_overlapping_targets
	
	#Se l'oggetto non era su alcuno slot, allora viene rimesso nella sua posizione iniziale
	if overlapping_targets.is_empty():
		object.global_position = starting_slot.global_position
		return
	
	#Se l'oggetto era su più di uno slot, allora si vede quale di questi fosse il più vicino
	elif overlapping_targets.size() > 1:
		var object_position = object.global_position
		var nearest_target_index = 0
		var for_iterator = 0
		var min_distance = null
		for target in overlapping_targets:
			var distance_from_package = target.global_position.distance_to(object.global_position)
			if min_distance == null or min_distance > distance_from_package:
				nearest_target_index = for_iterator
				min_distance = distance_from_package
			for_iterator += 1
		final_target = overlapping_targets[nearest_target_index]
	
	#Se l'oggetto era su un solo slot, la scelta del target è piuttosto semplice...
	else:
		final_target = overlapping_targets[0]
	
	#Prepariamo le variabili con gli id (formati dalla loro posizione) degli slot di partenza e di arrivo
	var final_target_id = str(final_target.global_position)
	var starting_target_id = str(starting_slot.global_position)
	
	#Eliminiamo dal dizionario degli slot occupati, lo slot di partenza
	occupied_slots.erase(starting_target_id)
	
	#Se lo slot a cui vogliamo assegnare l'oggetto è già occupato...
	if occupied_slots.has(final_target_id):
		#Spostiamo l'oggetto che occupa lo slot nella posizione iniziale del nostro pacchetto aggiornando il dizionario degli slot occupati
		occupied_slots[starting_target_id] = occupied_slots.get(final_target_id)
		occupied_slots.get(starting_target_id).global_position = starting_slot.global_position
	
	#Assegnamo l'oggetto al nuovo slot aggiornando il dizionario degli slot occupati
	occupied_slots[final_target_id] = object
	object.global_position = final_target.global_position
	
	#Assegnamo il pacchetto ai pacchetti equipaggiati
	if !(starting_slot.get_groups() == final_target.get_groups()):
		if final_target.is_in_group("import_package_slot"):
			#Sposta l'oggetto dai pacchetti del giocatore ai pacchetti equipaggiati e ne cambia il nodo padre
			Global.equip_package(object.package_id)
			packages_node.remove_child(object) 
			equipped_packages_node.add_child(object) 
			#Se la posizione iniziale è ancora presente tra gli slot occupati (e quindi vi è stato uno scambio con un altro oggetto) sposta l'oggetto scambiato dai pacchetti equipaggiati a quelli del giocatore e ne cambia il nodo padre
			if occupied_slots.has(starting_target_id):
				Global.unequip_package(occupied_slots.get(starting_target_id).package_id)
				equipped_packages_node.remove_child(occupied_slots.get(starting_target_id)) 
				packages_node.add_child(occupied_slots.get(starting_target_id)) 
		else:
			#Sposta l'oggetto dai pacchetti equipaggiati ai pacchetti del giocatore e rimuovi le classi del pacchetto dalle mosse del giocatore
			Global.unequip_package(object.package_id)
			equipped_packages_node.remove_child(object) 
			packages_node.add_child(object) 
			_remove_package_classes_from_moves(object.package_id)
			#Se la posizione iniziale è ancora presente tra gli slot occupati (e quindi vi è stato uno scambio con un altro oggetto) sposta l'oggetto scambiato dai pacchetti del giocatore a quelli equipaggiati
			if occupied_slots.has(starting_target_id):
				Global.equip_package(occupied_slots.get(starting_target_id).package_id)
				packages_node.remove_child(occupied_slots.get(starting_target_id)) 
				equipped_packages_node.add_child(occupied_slots.get(starting_target_id)) 
	

@onready var package_information_box = $PC1Menu/PackageInformationBox
func _pc1_on_pressed_object(object):
	package_information_box.pop_in(object.package_id)


func _remove_player_package(object_id : String):
	#Rimuoviamo il pacchtto dall'inventario del giocatore
	var is_equipped = Global.remove_player_package(object_id)
	#Facciamo sparire l'information box
	package_information_box.pop_out()
	
	#Eliminiamo il pacchetto e il conseguente slot dal dizionario degli slot occupati
	for slot_key in occupied_slots.keys():
		if occupied_slots.get(slot_key).package_id == object_id:
			occupied_slots.erase(slot_key)
			break
	
	#Eliminiamo il pacchetto dal menu PC1
	var packages_container_node
	if is_equipped:
		packages_container_node = equipped_packages_node
	else:
		packages_container_node = packages_node
	
	for package in packages_container_node.get_children():
		if package.package_id == object_id:
			package.queue_free()
			break
	
	#Eliminiamo le classi contenute nel pacchetto dalle mosse
	_remove_package_classes_from_moves(object_id)
	

#Elimina le classi contenute nel pacchetto dalle mosse
func _remove_package_classes_from_moves(object_id : String):
	
	var classes_ids_in_deleted_package = Global.get_package_by_id(object_id).classes
	for move in Global.moves.values():
		var keys_to_remove = []
		var iterator = 0
		for puzzle_piece in move.pieces_register.values():
			var key = move.pieces_register.keys()[iterator]
			for class_id in classes_ids_in_deleted_package:
				if puzzle_piece.get("object_id") == class_id:
					keys_to_remove.append(key)
			iterator +=1
		
		for key in keys_to_remove:
			move.remove_piece(key)


func _pop_out_window(window : Node):
	window.pop_out()
	pass





#///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

# PC 2
##Numero di righe e colonne che formano la griglia per posizionare pezzi di puzzle nella schermata di coding nel menu PC2
@export var puzzle_grid_size : Vector2 = Vector2(4,3)
##Impostazione di default della schermata degli oggetti nell'inventario nel menu PC2
@export_enum("code_pieces", "classes") var default_object_window_type : String = "classes"
@export var pc2_description_words_colors = {"fire" : "#ff0000", "water" : "#0c71c3", "grass" : "#00ea12", "normal" : "#00c191", "support": "#ffdd00"}
@export var description_font_size = {1 : 50, 2 : 50, 3: 50, 4 : 50, 5 : 45, 6 : 40}
@export var max_code_pieces_in_moves = {0 : 1, 1 : 2, 2: 3}

@onready var pc2_node = $PC2Menu
@onready var coding_window_label = $PC2Menu/CodingWindow/WindowName
@onready var method_description = $PC2Menu/CodingWindow/Description
@onready var time_label = $PC2Menu/TimeAndPiecesWindows/TimeLabel
@onready var pieces_limit_label = $PC2Menu/TimeAndPiecesWindows/PiecesLimitLabel
@onready var object_slots_node = $PC2Menu/ClassesAndCodePiecesWindow/ObjectSlots
@onready var previous_page_button = $PC2Menu/ClassesAndCodePiecesWindow/PagesButtons/PreviousPageButton
@onready var next_page_button = $PC2Menu/ClassesAndCodePiecesWindow/PagesButtons/NextPageButton
@onready var player_objects_node = $PC2Menu/PlayerObjects
@onready var classes_code_pieces_window_label = $PC2Menu/ClassesAndCodePiecesWindow/WindowName
@onready var move_pieces_node = $PC2Menu/MovePieces
@onready var animation_player = $PC2Menu/AnimationPlayer
@onready var root_puzzle_piece = $PC2Menu/MovePieces/RootPuzzlePiece
@onready var stored_slot = $PC2Menu/ClassesAndCodePiecesWindow/StoredSlot
@onready var description_container = $PC2Menu/CodingWindow/Description/DescriptionViewport/DescriptionContainer

var description_texts_dir_path = "res://assets/texts/moves_description_texts/"
var puzzle_piece_path : String = "res://scenes/assets_shop/PuzzlePiece.tscn"
var description_line_path : String = "res://scenes/assets_shop/DescriptionTextLine.tscn"
var puzzle_piece_scene = load(puzzle_piece_path)
var menu_method : String = ""
var current_object_window_type = ""
var current_object_window_page
var previous_page_button_state
var next_page_button_state
var is_code_piece_limit_reached

var id_piece_table = {} #Tabella delle corrispondenze tra id del pezzo e pezzo
var last_id_in_id_piece_table : int = -1 #Ultimo id inserito nella tabella delle corrispondenze tra id del pezzo e pezzo

var description_paths_register = {}

func _inizialize_pc2():
	$PC2Menu/CodingWindow/Description.texture = $PC2Menu/CodingWindow/Description/DescriptionViewport.get_texture();

func _set_pc2(input_method : String):
	#Assegnamo il nome del metodo
	menu_method = input_method
	#Cambia i label a seconda del metodo
	
	#Inizializziamo il root del puzzle
	root_puzzle_piece.set_root_puzzle_piece(puzzle_grid_size, menu_method)
	#Settiamo la finestra degli oggetti nell'inventario come definito nell'editor
	_switch_object_type_in_pc2_menu(default_object_window_type)
	#Carica i pezzi
	_erase_all_puzzle_pieces_from_pc2_menu()
	_load_move_in_pc2_menu()
	_update_recharge_time()
	_update_coding_window_title()
	
	#Carichiamo la descrizione
	description_paths_register = Global.get_move(menu_method).get_paths_register()
	_update_description()
	
	_check_code_pieces_limit_in_move()


func _check_code_pieces_limit_in_move():
	var num_code_pieces = 0
	var move = Global.get_move(menu_method)
	var max_num_code_pieces = max_code_pieces_in_moves.get(Global.max_code_piece_in_moves_lv)
	
	#Calcola il numero di code pieces nella mossa attuale
	for piece in move.pieces_register.values():
		if Global.is_code_piece(piece.get("object_id")):
			num_code_pieces += 1
	
	#Aggiorna il label
	pieces_limit_label.text = str(num_code_pieces, "/", max_num_code_pieces)
	
	#Se il numero di code pieces è uguale al limite allora disattiva i code_pieces stored nella schermata pc2
	if num_code_pieces == max_num_code_pieces:
		is_code_piece_limit_reached = true
		disable_all_code_pieces_in_pc2_menu()
		pieces_limit_label.modulate = Color("#ff0000")
	
	#Se il numero di code pieces è minore del limite allora attiva i stored code_pieces nella schermata pc2
	elif num_code_pieces < max_num_code_pieces:
		is_code_piece_limit_reached = false
		enable_all_code_pieces_in_pc2_menu()
		pieces_limit_label.modulate = Color("WHITE")

func disable_all_code_pieces_in_pc2_menu():
	if current_object_window_type == "code_pieces":
		for code_piece in player_objects_node.get_children():
			if "code_piece_id" in code_piece:
				code_piece.set_disabled()

func enable_all_code_pieces_in_pc2_menu():
	if current_object_window_type == "code_pieces":
		for code_piece in player_objects_node.get_children():
			if "code_piece_id" in code_piece:
				code_piece.set_enabled()

func _update_description():
	#Azzeriamo il description paths register
	description_paths_register.clear()
	for child in description_container.get_children():
		child.queue_free()
	#Definisci i percorsi collegati ai possibili effetti del metodo
	Global.get_move(menu_method).check_piece_for_create_description_path(-1, -1)
	description_paths_register = Global.get_move(menu_method).get_paths_register()
	#Genera una frase per ogni percorso
	var description_texts = _generate_description_texts()
	#Inserisci le frasi nella descrizione
	_display_description(description_texts)

func _display_description(description_texts):
	var iterator = 0
	for text in description_texts:
		var description_line_packed_scene = load(description_line_path)
		var description_line = description_line_packed_scene.instantiate()
		
		if iterator == 0:
			description_line.bullet_point_visible = false
		else:
			description_line.bullet_point_visible = true
		
		description_container.add_child(description_line)
		
		description_line.set_text(text, int(description_font_size.get(description_texts.size())))
		iterator += 1

func _generate_description_texts():
	var file_path = str(description_texts_dir_path, Global.language, "_moves_description_texts.txt")
	var file = FileAccess.open(file_path, FileAccess.READ)
	var default_phrases = {}
	var description_texts = []
	
	#Lettura del file .txt
	for i in file.get_as_text().count("|"):
			var line = file.get_line()
			var key = line.get_slice("|",0)
			var value = line.get_slice("|",1)
			value = str(value)
			default_phrases[key] = value
	file.close()
	
	#Creazione delle frasi
	#Se non ci sono path la frase è standard
	if description_paths_register.size() == 0:
		var single_text = str(default_phrases.get("first_phrase"), " ", default_phrases.get("then_nothing_phrase"),".")
		description_texts.append(single_text.to_upper())
	
	#Se esistono uno o più path bisogna creare una frase per ognuno di essi
	else:
		var is_only_one_path = description_paths_register.size() == 1
		
		if !is_only_one_path:
			var introduction_text = default_phrases.get("first_phrase")
			description_texts.append(str(introduction_text.to_upper(), ":"))
		
		for path in description_paths_register.values():
			var type = path.get("type")
			var class_id = path.get("class_id")
			var n_iterations = path.get("iterations")
			var class_title = ""
			var class_type = ""
			var type_text
			var class_text
			var final_punctuation
			
			if type != "empty":
				type_text = default_phrases.get("if_phrase")
				
			elif !is_only_one_path:
				type_text = default_phrases.get("else_phrase")
			else:
				type_text = ""
			
			if class_id == "empty":
				class_text = default_phrases.get("then_nothing_phrase")
			else:
				class_title = Global.get_class_by_id(class_id).object_class_name
				class_type = Global.get_class_by_id(class_id).get_type()
				
				if n_iterations == 1:
					class_text = str(default_phrases.get("then_phrase"), " ", default_phrases.get("singular_time"))
				else:
					class_text = str(default_phrases.get("then_phrase"), " ", default_phrases.get("multiple_times"))
			
			if description_paths_register.find_key(path) == description_paths_register.size() - 1:
				final_punctuation = "."
			else:
				final_punctuation = ";"
			
			var final_phrase = str(type_text, ", ", class_text, final_punctuation)
			
			var start_enemy_type_tag = str("[", "color=", pc2_description_words_colors.get(type), "]")
			var start_class_tag = str("[", "color=", pc2_description_words_colors.get(class_type), "]")
			var end_tag = str("[/color]")
			
			var tagged_type = str(start_enemy_type_tag, type.to_upper(), end_tag)
			var tagged_class_title = str(start_class_tag, class_title.to_upper(), end_tag)
			var tagged_iterations = str(start_class_tag, n_iterations, end_tag)
			final_phrase = final_phrase.to_upper()
			final_phrase = final_phrase.format({"TYPE" : tagged_type, "CLASS_TITLE" : tagged_class_title, "TIMES" : tagged_iterations})
			
			if is_only_one_path:
				final_phrase = str(default_phrases.get("first_phrase").to_upper(), final_phrase)
			
			description_texts.append(final_phrase)
	
	
	return description_texts

#INUTILIZZATA. SOSTITUITA CON LA STESSA FUNZIONE INTERNA ALLA MOSSA
func _check_piece_for_create_description_path(path_index : int, piece_index : int):
	var next_path_key : int
	var next_piece_key : int
	
	#Se queste condizioni sono vere vuol dire che lo slot del pezzo precedente era vuoto e quindi il path si è concluso
	if path_index != -1 and piece_index == -1:
		return
	
	#Per iniziare recuperiamo il path che stiamo percorrendo
	var path
	#Se è la prima chiamata di questa funzione crea un nuovo path con indice 0, altrimenti lo recupera dal registro
	if path_index == -1:
		
		#Se alla prima chiamata il registro dei pezzi è completamente vuoto, termina la creazione del description_paths_register
		if Global.get_move(menu_method).pieces_register.is_empty():
			return
		
		piece_index = Global.get_move(menu_method).get_first_piece_key()
		path = {"type" : "empty", "class_id" : "empty", "iterations" : 1, "checked_types" : []}
		path_index = 0
		description_paths_register[path_index] = path
	else:
		path = description_paths_register.get(path_index)
	
	#Recuperiamo il pezzo che stiamo esaminando
	var piece = Global.get_move(menu_method).get_piece_by_id(piece_index)
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
		_check_piece_for_create_description_path(next_path_key, next_piece_key)
	
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
					next_path_key = description_paths_register.size()
					description_paths_register[next_path_key] = new_path
			
				#Controlliamo che il tipo collegato non faccia parte dei checked types
				var path_type = "empty"
				if iterator != piece.get("children_pieces").size() - 1:
					path_type = object.types[iterator]
					if new_path.get("checked_types").has(path_type):
						iterator += 1
						description_paths_register.erase(next_path_key)
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
					_check_piece_for_create_description_path(next_path_key, next_piece_key)
		
		#Se il percorso ha già un tipo e l'if ha uno slot per quel tipo, il percorso continua solo su quello slot
		elif object.types.has(path.get("type")):
			next_path_key = path_index
			next_piece_key = piece.get("children_pieces")[object.types.find(path.get("type"))]
			_check_piece_for_create_description_path(next_path_key, next_piece_key)
		
		#Se il path ha già un tipo e l'if non ha uno slot per quel tipo, il percorso continua solo sullo slot dell'else
		else:
			next_path_key = path_index
			next_piece_key = piece.get("children_pieces")[piece.get("children_pieces").size() - 1]
			_check_piece_for_create_description_path(next_path_key, next_piece_key)



func _update_coding_window_title():
	var new_title
	if menu_method == "constructor":
		new_title = "Player.exe"
	else:
		new_title = str(menu_method.capitalize(), ".exe")
	coding_window_label.text = new_title

func update_object_window_title():
	var new_title
	if current_object_window_type == "classes":
		new_title = "Classes.exe"
	elif  current_object_window_type == "code_pieces":
		new_title = "Code Pieces.exe"
	classes_code_pieces_window_label.text = new_title

func _update_recharge_time():
	var move = Global.get_move(menu_method)
	var time_in_seconds = move.get_time()
	var time_string : String
	var minutes_string : String
	var seconds_string : String
	
	var minutes = floor(time_in_seconds/60)
	var seconds = time_in_seconds - (minutes * 60)
	
	if minutes < 10:
		minutes_string = str("0", minutes)
	else:
		minutes_string = str(minutes)
	
	if seconds < 10:
		seconds_string = str("0", seconds)
	else:
		seconds_string = str(seconds)
	
	time_string = str(minutes_string, ":", seconds_string)
	
	time_label.text = time_string

func _load_move_in_pc2_menu():
	#Resettiamo la id_piece_table e il last_id_in_id_piece_table
	id_piece_table.clear()
	last_id_in_id_piece_table = -1
	#Carichiamo i pezzi, sia graficamente che nella tabella id_piece_table
	_load_puzzle_piece_from_move(-1, -1)

func _erase_all_puzzle_pieces_from_pc2_menu():
	for piece in move_pieces_node.get_children():
		if !piece == root_puzzle_piece:
			piece.queue_free()

func _load_puzzle_piece_from_move(puzzle_piece_index : int, parent_puzzle_piece_index : int):
	var move = Global.get_move(menu_method)
	
	if move.is_move_empty():
		return
	if puzzle_piece_index == -1:
		puzzle_piece_index = move.get_first_piece_key()
	
	var puzzle_piece_object_id = move.get_piece_by_id(puzzle_piece_index).get("object_id")
	var puzzle_piece_form = move.get_piece_by_id(puzzle_piece_index).get("form")
	var puzzle_piece_children_indexes = move.get_piece_by_id(puzzle_piece_index).get("children_pieces")
	
	#Recuperiamo il pezzo di puzzle del padre
	var parent_puzzle_piece
	if parent_puzzle_piece_index == -1:
		parent_puzzle_piece = root_puzzle_piece
	else:
		parent_puzzle_piece = id_piece_table.get(parent_puzzle_piece_index)
	
	#Recuperiamo un riferimento allo slot a cui dovrebbe essere collegato il pezzo
	var parent_slot
	if parent_puzzle_piece_index == -1:
		parent_slot = root_puzzle_piece.central_piece_puzzle_slot
	else:
		var parent_children_indexes = move.get_piece_by_id(parent_puzzle_piece_index).get("children_pieces")
		var piece_slot_index = parent_children_indexes.find(puzzle_piece_index)
		parent_slot = parent_puzzle_piece.active_pieces[piece_slot_index].get_node("PuzzleSlot")
	
	#Otteniamo lo state del puzzle piece
	var puzzle_piece_state = "detachable"
	for child in puzzle_piece_children_indexes:
		if child != -1:
			puzzle_piece_state = "chained"
			break;
	
	#Controlliamo il tipo di oggetto
	var is_code_piece : bool = Global.is_code_piece(puzzle_piece_object_id)
	
	#Genera il pezzo del puzzle
	var puzzle_piece = puzzle_piece_scene.instantiate()
	move_pieces_node.add_child(puzzle_piece)
	move_pieces_node.move_child(puzzle_piece,0)
	puzzle_piece.set_puzzle_piece_from_move_loading(is_code_piece, puzzle_piece_object_id, puzzle_piece_form, puzzle_piece_state, puzzle_grid_size)
	
	#Connetti i segnali del DragAndDropObjectComponent
	if puzzle_piece.has_node("DragAndDropObjectComponent"):
		puzzle_piece.get_node("DragAndDropObjectComponent").on_drag_drag_and_drop_object.connect(_on_drag_drag_and_drop_object)
		puzzle_piece.get_node("DragAndDropObjectComponent").on_drop_drag_and_drop_object.connect(_on_drop_drag_and_drop_object)
		puzzle_piece.get_node("DragAndDropObjectComponent").on_button_pressed_drag_and_drop_object.connect(_on_button_pressed_drag_and_drop_object)
	
	#Setta la posizione
	puzzle_piece.set_puzzle_piece_position(parent_slot.position_on_grid)
	puzzle_piece.global_position = parent_slot.global_position
	puzzle_piece.scale = Vector3(0.15, 0.15, 0.15)
	
	#Aggiungiamolo all'id_piece_table e aggiorniamo il last_id_in_id_piece_table
	id_piece_table[puzzle_piece_index] = puzzle_piece
	if puzzle_piece_index > last_id_in_id_piece_table:
		last_id_in_id_piece_table = puzzle_piece_index
	
	
	#Aggiorniamo lo slot del pezzo genitore
	puzzle_piece.connected_to_slot = parent_slot
	parent_slot.set_connected_node(puzzle_piece)
	
	#Per ogni figlio in children_pieces (diverso da -1) richiama questa funzione ricorsivamente
	for child in puzzle_piece_children_indexes:
		if child != -1:
			_load_puzzle_piece_from_move(child, puzzle_piece_index)


#Aggiorna la tabella id_piece_table e aggiunge il nuovo pezzo alla mossa corrispondente in Global
func _add_piece_to_move(puzzle_piece : Area3D):
	#Creiamo il suo nuovo id, prendendo quello dell'ultimo elemento inserito e aggiungendo 1
	var new_id = last_id_in_id_piece_table + 1
	last_id_in_id_piece_table = new_id
	
	#Inseriamo il nuovo pezzo nella tabella id_piece_table
	id_piece_table[new_id] = puzzle_piece
	
	
	#Recuperiamo l'id del pezzo padre
	var connected_to_slot = puzzle_piece.connected_to_slot
	var parent_piece = connected_to_slot.parent_puzzle_piece
	var parent_piece_id
	if id_piece_table.size() > 1:
		parent_piece_id = id_piece_table.find_key(parent_piece)
	else:
		parent_piece_id = -1
	
	#Recuperiamo l'index dello slot a cui è stato connesso il pezzo da aggiungere
	var parent_slot_position
	var iterator = -1
	for active_piece in parent_piece.active_pieces:
		iterator += 1
		if active_piece.get_node("PuzzleSlot") == connected_to_slot:
			parent_slot_position = iterator
			break
	
	#Inseriamo il nuovo pezzo nella mossa corrispondente
	var move = Global.get_move(menu_method)
	move.add_piece(new_id, puzzle_piece.object.id, puzzle_piece.form, parent_piece_id, parent_slot_position)
	
	_update_recharge_time()
	
	_update_description()
	
	#Aggiorna il sistema che si occupa di verificare se il numero di code pieces presenti all'interno della mossa superi il limite
	_check_code_pieces_limit_in_move()




#Aggiorna la tabella id_piece_table e rimuove il pezzo alla mossa corrispondente in Global
func _remove_piece_from_move(puzzle_piece : Area3D):
	#Rimuoviamo il pezzo dalla tabella id_piece_table
	var piece_id = id_piece_table.find_key(puzzle_piece)
	id_piece_table.erase(piece_id)
	
	#Rimuoviamo il pezzo dalla mossa in Global
	var move = Global.get_move(menu_method)
	move.remove_piece(piece_id)
	
	_update_recharge_time()
	
	_update_description()
	
	#Aggiorna il sistema che si occupa di verificare se il numero di code pieces presenti all'interno della mossa superi il limite
	_check_code_pieces_limit_in_move()




func _switch_object_type_in_pc2_menu(to_type : String):
	current_object_window_type = to_type
	current_object_window_page = 1
	_despawn_all_player_objects_in_pc2_menu()
	_spawn_player_objects_in_pc2_menu(to_type, 1)
	
	_check_pages_buttons()
	
	var animation_name = str("on_", to_type, "_button_click")
	animation_player.play(animation_name)
	
	update_object_window_title()
	
	#Se sono code pieces, verifica se devono essere disattivati a causa del raggiungimento da parte della mossa del limite di pezzi massimo
	if is_code_piece_limit_reached:
		disable_all_code_pieces_in_pc2_menu()
	else:
		enable_all_code_pieces_in_pc2_menu()
#


func _change_page_in_pc2_menu(is_next : bool):
	#Controlliamo se il pulsante sia disabilitato
	if is_next and next_page_button_state == "disabled":
		return
	if !is_next and previous_page_button_state == "disabled":
		return
	
	_despawn_all_player_objects_in_pc2_menu()
	if is_next:
		current_object_window_page += 1
	else:
		current_object_window_page -= 1
	_spawn_player_objects_in_pc2_menu(current_object_window_type, current_object_window_page)
	
	_check_pages_buttons()
	
	


func _spawn_player_objects_in_pc2_menu(object_type : String, page_number : int):
	var objects_ids = []
	var slots = object_slots_node.get_children()
	var object_scene
	var starting_index = (page_number - 1) * slots.size()
	
	var pc2_stored_class_scene = preload("res://scenes/assets_shop/PC2StoredClass.tscn")
	var pc2_stored_code_piece_scene = preload("res://scenes/assets_shop/PC2StoredCodePiece.tscn")
	
	#Carichiamo gli id degli oggetti del giocatore e creiamo gli oggetti da far spawnare
	if object_type == "classes":
		object_scene = pc2_stored_class_scene
		var equipped_packages_id = Global.equipped_packages
		objects_ids = Global.get_player_classes_ids()
	
	elif object_type == "code_pieces": 
		object_scene = pc2_stored_code_piece_scene
		objects_ids = Global.player_code_pieces
	
	else:
		pass
	
	#Spawniamo gli oggetti
	var iterator = 0
	for slot in slots:
		if objects_ids.size() <= (iterator + starting_index):
			break
		var object_id = objects_ids[iterator + starting_index]
		var object = object_scene.instantiate()
		object.set_object(object_id)
		player_objects_node.add_child(object)
		object.global_position = slot.global_position
		object.scale = Vector3(0.16, 0.16, 0.16)
		
		#Connetti i segnali del DragAndDropObjectComponent
		if object.has_node("DragAndDropObjectComponent"):
			object.get_node("DragAndDropObjectComponent").on_drag_drag_and_drop_object.connect(_on_drag_drag_and_drop_object)
			object.get_node("DragAndDropObjectComponent").on_drop_drag_and_drop_object.connect(_on_drop_drag_and_drop_object)
			object.get_node("DragAndDropObjectComponent").on_button_pressed_drag_and_drop_object.connect(_on_button_pressed_drag_and_drop_object)
		
		iterator += 1
	

#Elimina tutti gli oggetti presenti nella finestra degli oggetti del menu PC2
func _despawn_all_player_objects_in_pc2_menu():
	for object in player_objects_node.get_children():
		object.queue_free()


func _check_pages_buttons():
	#Check sul pulsante per tornare indietro
	if current_object_window_page == 1:
		_disable_pages_button(false)
	else:
		_enable_pages_button(false)
	
	
	#Check sul pulsante per andare avanti
	var slots_quantity_for_page = object_slots_node.get_children().size()
	var player_objects_quantity
	
	if current_object_window_type == "classes":
		player_objects_quantity = Global.get_player_classes_ids().size()
	else:
		player_objects_quantity = Global.player_code_pieces.size()
	
	if player_objects_quantity > (current_object_window_page * slots_quantity_for_page):
		_enable_pages_button(true)
	else:
		_disable_pages_button(true)


func _disable_pages_button(is_next : bool):
	if is_next:
		next_page_button_state = "disabled"
		next_page_button.get_node("ButtonComponent").set_disabled()
		for node in next_page_button.get_children():
			if node.is_class("Sprite3D"):
				node.modulate = Color("#a0a0a0")
	else:
		previous_page_button_state = "disabled"
		previous_page_button.get_node("ButtonComponent").set_disabled()
		for node in previous_page_button.get_children():
			if node.is_class("Sprite3D"):
				node.modulate = Color("#a0a0a0")

func _enable_pages_button(is_next : bool):
	if is_next:
		next_page_button_state = "enabled"
		next_page_button.get_node("ButtonComponent").set_enabled()
		for node in next_page_button.get_children():
			if node.is_class("Sprite3D"):
				node.modulate = Color("WHITE")
	else:
		previous_page_button_state = "enabled"
		previous_page_button.get_node("ButtonComponent").set_enabled()
		for node in previous_page_button.get_children():
			if node.is_class("Sprite3D"):
				node.modulate = Color("WHITE")



var dragged_object_starting_position : Vector3
var temp_stored_object_moved #Riferimento ad uno stored code piece/class che è diventato invisibile/più scuro dopo la creazione del corrispettivo pezzo di puzzle
func _pc2_on_drag_stored_object(object : Area3D, overlapping_targets : Array):
	
	#Controlliamo il tipo di oggetto
	var is_code_piece : bool = false
	var object_id : String
	if "code_piece_id" in object:
		is_code_piece = true
		object_id = object.code_piece_id
	else:
		object_id = object.class_id
	
	#Genera il pezzo del puzzle
	var puzzle_piece = puzzle_piece_scene.instantiate()
	move_pieces_node.add_child(puzzle_piece)
	move_pieces_node.move_child(puzzle_piece,0)
	puzzle_piece.set_puzzle_piece_from_stored_object(is_code_piece, object_id, puzzle_grid_size)
	
	#Connetti i segnali del DragAndDropObjectComponent
	if puzzle_piece.has_node("DragAndDropObjectComponent"):
		puzzle_piece.get_node("DragAndDropObjectComponent").on_drag_drag_and_drop_object.connect(_on_drag_drag_and_drop_object)
		puzzle_piece.get_node("DragAndDropObjectComponent").on_drop_drag_and_drop_object.connect(_on_drop_drag_and_drop_object)
		puzzle_piece.get_node("DragAndDropObjectComponent").on_button_pressed_drag_and_drop_object.connect(_on_button_pressed_drag_and_drop_object)
	
	#Setta la posizione
	puzzle_piece.global_position = Vector3(object.global_position.x ,object.global_position.y, object.global_position.z)
	puzzle_piece.scale = Vector3(0.15, 0.15, 0.15)
	
	#Settalo in modo da essere in stato "dragged"
	puzzle_piece.get_node("DragAndDropObjectComponent").force_drag()
	
	dragged_object_starting_position = overlapping_targets[0].global_position
	
	if is_code_piece:
		#Lo rende invisibile. Se, quando droppato, il pezzo di puzzle trova una nuova posizione allora questo object viene definitivamente cancellato, 
		#altrimenti viene reso nuovamente visibile ed è il pezzo di codice ad essere cancellato
		object.visible = false
	else:
		object.on_puzzle_piece_drag()
	
	#Risetta la posizione iniziale dell'oggetto
	object.global_position = dragged_object_starting_position
	object.get_node("DragAndDropObjectComponent").force_drop()
	
	temp_stored_object_moved = object
	
	#Mostra le posizioni in cui è possibile collocare il pezzo di puzzle
	_enable_valid_puzzle_slots(puzzle_piece)
	
	#Attiviamo lo stored_slot
	_enable_stored_slot()


func _pc2_on_pressed_stored_object(object : Area3D):
	print("Connesso Pressed")
	pass

func _pc2_on_drag_puzzle_piece(puzzle_piece, overlapping_targets):
	#Settiamo il pezzo a cui era connesso come detachable e il connected_node dello slot a null
	var ex_connected_slot = puzzle_piece.connected_to_slot
	var ex_connected_piece = ex_connected_slot.parent_puzzle_piece
	ex_connected_slot.set_connected_node(null)
	if !ex_connected_piece.should_be_chained():
		ex_connected_piece.set_state("detachable")
	
	#Settiamo il pezzo come dragged
	puzzle_piece.set_state("dragged")
	
	#Attiviamo i puzzle_slots
	_enable_valid_puzzle_slots(puzzle_piece)
	
	#Attiviamo lo stored_slot
	_enable_stored_slot()
	
	#Lo elimina dai pezzi della mossa
	_remove_piece_from_move(puzzle_piece)
	


func _pc2_on_drop_puzzle_piece(object, overlapping_targets):
	var final_target #Variabile in cui si inserisce lo slot in cui verrà spostato il pacchetto
	var is_code_piece = object.is_code_piece
	
	#Puliamo l'array in input da tutte le aree rilevate che non siano slot (PS La duplicazione è necessaria in quanto rimuovere elementi da una array durante una sua iterazione può far saltare alcuni elementi dell'array stesso)
	var temp_overlapping_targets = overlapping_targets.duplicate()
	for area in overlapping_targets:
			if !area.is_in_group("pc2_puzzle_slot"):
				temp_overlapping_targets.erase(area) 
	overlapping_targets = temp_overlapping_targets
	
	#Se l'oggetto non era su alcuno slot...
	if overlapping_targets.is_empty():
		
		#Se era precedentemente attaccato ad un altro pezzo, ritorna in quella posizione e viene ri-attaccato
		if object.connected_to_slot != null:
			object.global_position = object.connected_to_slot.global_position
			object.drop_puzzle_piece_on_grid(object.connected_to_slot)
			object.connected_to_slot.set_connected_node(object)
			_add_piece_to_move(object)
		
		#Se invece veniva dall'inventario, ci torna
		else:
			if is_code_piece:
				temp_stored_object_moved.visible = true
			object.queue_free()
	
	#Altrimenti...
	else:
		#Se l'oggetto era su più di uno slot, allora si vede quale di questi fosse il più vicino
		if overlapping_targets.size() > 1:
			var object_position = object.global_position
			var nearest_target_index = 0
			var for_iterator = 0
			var min_distance = null
			for target in overlapping_targets:
				var distance_from_package = target.global_position.distance_to(object.global_position)
				if min_distance == null or min_distance > distance_from_package:
					nearest_target_index = for_iterator
					min_distance = distance_from_package
				for_iterator += 1
			final_target = overlapping_targets[nearest_target_index]
			
		#Se l'oggetto era su un solo slot, la scelta del target è piuttosto semplice...
		else:
			final_target = overlapping_targets[0]
		
		
		#Se il pezzo è stato rilasciato sullo slot dell'inventario...
		if final_target.is_in_group("pc2_stored_slot"):
			#Se è un pezzo di codice che precedentemente era nel puzzle, aggiunge il pezzo all'inventario e refresha la schermata dell'inventario se necessario
			if is_code_piece and temp_stored_object_moved == null:
				Global.add_player_s_code_piece (object.object.id, 0)
				if (current_object_window_type == "code_pieces"):
					_despawn_all_player_objects_in_pc2_menu()
					_spawn_player_objects_in_pc2_menu("code_pieces", current_object_window_page)
			#Se è un pezzo di codice che già veniva dall'inventario, ci torna
			elif is_code_piece and temp_stored_object_moved != null:
				temp_stored_object_moved.visible = true
			else:
				pass
			object.queue_free()
		
		#Se il pezzo è stato rilasciato su uno slot, viene collegato al pezzo corrispondente
		else:
			object.global_position = final_target.global_position
			object.drop_puzzle_piece_on_grid(final_target)
			final_target.set_connected_node(object)
			_add_piece_to_move(object)
			
			#Se l'oggetto è un pezzo di codice, questo viene eliminato dagli oggetti dell'inventario
			if is_code_piece:
				Global.delete_player_s_code_piece_by_id(object.object.id) 
				if object.connected_to_slot != null:
					#Elimina lo stored code piece
					if temp_stored_object_moved != null:
						temp_stored_object_moved.queue_free()
		
	
	
	#Ri-illumina la stored class al drop del puzzle piece
	if !is_code_piece and temp_stored_object_moved != null:
		temp_stored_object_moved.on_puzzle_piece_drop()
	
	#Svuotiamo il temp_stored_object_moved
	temp_stored_object_moved = null
	
	#Disabilita i puzzle_slots (slot in cui rilasciare il pezzo)
	_disable_puzzle_slots()
	
	#Disabilita lo stored slot
	_disable_stored_slot()
	
	


func _enable_valid_puzzle_slots(puzzle_piece : Area3D):
	for piece in move_pieces_node.get_children():
		piece.enable_puzzle_slots(puzzle_piece)


func _disable_puzzle_slots():
	for piece in move_pieces_node.get_children():
		piece.disable_puzzle_slots()


func _enable_stored_slot():
	stored_slot.visible = true
	stored_slot.get_node("CollisionShape3D").disabled = false
	stored_slot.get_node("AnimationPlayer").play("glow")


func _disable_stored_slot():
	stored_slot.visible = false
	stored_slot.get_node("CollisionShape3D").disabled = true
	stored_slot.get_node("AnimationPlayer").stop()


#///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



#GESTIONE MOVIMENTI DI CAMERA

var from : String = ""
var to : String = "main_menu"

#Se la camera si sta muovendo da un menu ad un altro è possibile skippare la transizione tramite un semplice tocco
func _on_input_component_on_tap_start(tap_position):
	if state.contains("moving_camera"):
		anim_player.advance(5)


func _on_animation_player_animation_finished(anim_name):
	#Una volta premuto il pulsante, un flash verrà lanciato. Alla sua massima luminosità (fine dell'animazione "flash_in"), verrà lanciata l'animazione che muove la camera da uno sho all'altro
	if anim_name.contains("flash_in"):
		lunas_camera_path.change_path(from, to)
		lunas_camera.make_current()
		anim_player.play(str("move_camera_from_", from, "_to_", to))
		state = str("moving_camera_from_", from, "_to_", to)
		return
	
	#Quando il movimento di camera finisce...
	if state.contains("moving_camera"):
		state = str("on_", to)
		
		if (from.contains("pc") and to.contains("pc")):
			from = ""
			to = ""
			return
		
		var camera = cameras.get(str(to, "_camera"))
		camera.make_current()
		anim_player.play(str(to, "_flash_out"))
		camera.shake("strong")
		
		main_menu_camera.shake("strong")
		from = ""
		to = ""

func _change_menu (input_from : String, input_to :String):
	from = input_from
	to = input_to
	
	if (from.contains("pc") and to.contains("pc")):
		anim_player.play(str("move_camera_from_", from, "_to_", to))
		state = str("moving_camera_from_", from, "_to_", to)
		return
	
	anim_player.play(str(from, "_flash_in"))










#GESTIONE DEI SEGNALI

#Chiamato alla pressione di un tasto dedito al cambio del menu
func on_change_menu_request(from : String, to : String):
	_change_menu(from, to)

func on_product_selection(index : int):
	if shop_selected_product_index == index:
		_deselect_current_product()
	else:
		_set_current_product(index)
	_update_buy_button_state()

func _on_buy_button_press():
	if buy_button_state == "disabled":
		#Dovrei creare una scena per piccoli messaggi di errore che spieghino il problema. In questo caso: "Non hai abbastanza soldi per quest'oggetto"
		pass
	else:
		_shop_buy_selected_product()

func _on_rest_button_press():
	_on_rest()

func _on_alert_box_launch(alert_box_name : String):
	var alert_box = self.get_node(alert_box_name)
	alert_box.pop_in()

func _on_alert_box_cancel(alert_box_name : String):
	var alert_box = self.get_node(alert_box_name)
	alert_box.pop_out()

func _on_change_scene_to_map(from_scene : String, progress : bool):
	var transfer_data = {}
	transfer_data["progress"] = progress
	Global.change_scene_to_map(from_scene, transfer_data)

func _on_drag_drag_and_drop_object(object : Area3D, overlapping_targets : Array):
	if object.is_in_group("pc1_package"):
		_pc1_on_drag_object(object, overlapping_targets)
	elif object.is_in_group("pc2_stored_class") or object.is_in_group("pc2_stored_code_piece"):
		_pc2_on_drag_stored_object(object, overlapping_targets)
	elif object.is_in_group("pc2_puzzle_piece"):
		_pc2_on_drag_puzzle_piece(object, overlapping_targets)

func _on_drop_drag_and_drop_object(object : Area3D, overlapping_targets : Array):
	if object.is_in_group("pc1_package"):
		_pc1_on_drop_object(object, overlapping_targets)
	elif object.is_in_group("pc2_puzzle_piece"):
		_pc2_on_drop_puzzle_piece(object, overlapping_targets)

func _on_button_pressed_drag_and_drop_object(object : Area3D):
	if object.is_in_group("pc1_package"):
		_pc1_on_pressed_object(object)
	elif object.is_in_group("pc2_stored_class") or object.is_in_group("pc2_stored_code_piece"):
		_pc2_on_pressed_stored_object(object)
	elif object.is_in_group("pc2_puzzle_piece"):
		pass

func _on_remove_player_object(object_id : String, object_type: String):
	if object_type == "package":
		if Global.packages.has(object_id):
			_remove_player_package(object_id)
	
	elif object_type == "code_piece":
		if Global.code_pieces.has(object_id):
			pass

func _on_pop_out_window(window : Node):
	if window.has_method("pop_out"):
		_pop_out_window(window)


func _on_change_menu_request_to_pc2(pc2_method : String):
	_change_menu("pc1_menu", "pc2_menu")
	_set_pc2(pc2_method)


func _on_lunas_change_page_in_object_window_in_pc2_menu(is_next : bool):
	_change_page_in_pc2_menu(is_next) 


func _on_lunas_change_object_type_in_object_window_in_pc2_menu(to_type : String):
	_switch_object_type_in_pc2_menu(to_type)
