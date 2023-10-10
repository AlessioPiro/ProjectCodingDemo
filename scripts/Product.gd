extends Area3D

var index : int
var product
var icon
var price
var state #Stati disponibile: too_expensive, buyable, sold_out

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#Inizializzazione del prodotto
func set_product(input_product : Node2D, product_price : int, product_index : int):
	product = input_product
	state = "buyable"
	index = product_index
	icon = product.icon
	$ProductSprite.texture = icon
	price = product_price
	$Price.text = str("$",price)
	check_is_too_expensive()
	
	if product.get("code_piece_name"):
		
		$FrameSprite.texture = preload("res://assets/icons/code_piece_icons/code_piece_icon.png")
		$BackgroundSprite.texture = preload("res://assets/icons/code_piece_icons/code_piece_background.png")
		
		if product.category == "if" or product.category == "else_if":
			$Type.visible = true
			var path_string = str("res://assets/icons/type_icons/", product.types[0], "_icon.png")
			$Type.texture = load(path_string)
			$Type/TypeShadow.texture = load(path_string)
			$Type.modulate = _set_type_color(product.types[0])
		if product.category == "else_if":
			$Type2.visible = true
			var path_string_2 = str("res://assets/icons/type_icons/", product.types[1], "_icon.png")
			$Type2.texture = load(path_string_2)
			$Type2/TypeShadow2.texture = load(path_string_2)
			$Type2.modulate = _set_type_color(product.types[1])

#Cambia il colore delle icone dei tipi sui pezzi di codice di tipo if ed if_else
func _set_type_color(type : String):
	var hex_value
	match (type):
		"fire":
			hex_value = "ff0000"
		"water":
			hex_value = "0c71c3"
		"grass":
			hex_value = "00ea12"
		"normal":
			hex_value = "00c191"
	return Color.html(hex_value)

#Attiva il quadrante di selezione
func set_current():
	$SelectionSprite.set_visible(true)
	pass

#Deseleziona il prodotto se attivo
func deselect_current():
	$SelectionSprite.set_visible(false)
	pass

#Cambia colore se il giocatore non ha abbastanza credito per acquistarlo
func check_is_too_expensive():
	if Global.game_money < price and state != "too_expensive":
		state = "too_expensive"
		_change_product_appearance()

func set_sold_out():
	state = "sold_out"
	_change_product_appearance()

func _change_product_appearance():
	if state == "too_expensive":
		for i in get_children():
			if i.is_class("Sprite3D") and !i.get_name().contains("Selection"):
				i.modulate = i.modulate.darkened(0.7)
			elif i.is_class("Label3D"):
				i.modulate = Color("RED")
	
	elif state == "sold_out":
		for i in get_children():
			if i.is_class("Sprite3D") and !i.get_name().contains("Selection"):
				i.modulate = Color("BLACK")
			elif i.is_class("Label3D"):
				i.modulate = Color("RED")
				i.text = "SOLD OUT"
				i.font_size = 80
