extends Control


@onready var cardozo_button = $ColorRect/TabContainer/Cube/Cardozo
@onready var bloom_button = $ColorRect/TabContainer/Cube/Bloom
@onready var hagood_button = $ColorRect/TabContainer/Cube/Hagood
@onready var debug_label = $ColorRect/DebugLabel

func _ready():
	debug_label.text = "debug label :)"

	cardozo_button.pressed.connect(_on_cardozo_pressed)
	bloom_button.pressed.connect(_on_bloom_pressed)
	hagood_button.pressed.connect(_on_hagood_pressed)

func _on_cardozo_pressed():
	debug_label.text = "Cardozo selected"

func _on_bloom_pressed():
	debug_label.text = "Bloom selected"

func _on_hagood_pressed():
	debug_label.text = "Hagood selected"
