extends Resource
class_name BattleElementSignalManager

#SEGNALI

##Segnali legati agli HP
signal damage(amount : int, is_super_effective : bool, is_not_effective : bool, is_crit : bool) #Segnale che comunica la richiesta di infliggere un danno all'elemento selezionato
signal hp_lowered(amount : int) #Segnale che comunica che gli HP dell'elemento sono stati abbassati
signal death() #Segnale che comunica la morte dell'elemento
signal hp_recover(amount : int, is_percentage : bool) #Segnale che comunica la richiesta di che gli HP dell'elemento sono stati alzati
signal heal(amount : int)  #Segnale che comunica il lancio di una cura nei confronti dell'elemento

##Segnali legati alle statistiche
signal buff(buff_amount, buff_stat) #Segnale che comunica la richiesta di buff di una statistica
signal debuff(debuff_amount, debuff_stat) #Segnale che comunica la richiesta di debuff di una statistica
signal stat_buffed(amount, stat) #Segnale che comunica l'effettivo buff della statistica
signal stat_debuffed(amount, stat) #Segnale che comunica l'effettivo debuff della statistica

#Segnali legati alle collisioni
signal collision(area) #Segnale che comunica che è avvenuta una collisione con un nodo di tipo "Area3D"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
