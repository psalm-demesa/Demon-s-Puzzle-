extends Node2D

@onready var buttons = $GridContainer.get_children()

const SIZE = 5

var wordle:String = ""
var index = 0 # Position of button text to be updated
var latest_row_index = 0
var row_filled = false

# Called when the node enters the scene tree for the first time.
func _ready():
	init_button_styles()
	reset_game()

func _input(event):
	if event is InputEventKey and event.is_pressed():
		if event.keycode >= KEY_A and event.keycode <= KEY_Z:
			var letter = char(event.keycode)
			print("letter: ", letter)
			
			if not row_filled:
				buttons[index].text = letter
				index += 1 
			
				if index != 0 and index % 5 == 0:
					row_filled = true
			
	if Input.is_action_pressed("back"):
		if index > 0 and index > latest_row_index:
			index -= 1
			buttons[index].text = ""
			row_filled = false
	if Input.is_action_pressed("enter"):
		#Only check win when an entire row is filled
		if row_filled:
			latest_row_index = index - SIZE
			check_win()
			row_filled = false

func reset_game():
	wordle = get_random_wordle()
	print("Wordle: ", wordle)
	for button in buttons:
		var b = button as Button
		b.text = ""

func init_button_styles():
	for button in buttons:
		var b = button as Button
		var style = StyleBoxFlat.new()
		style.bg_color = Color.BLACK
		style.border_color = Color.DIM_GRAY
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
		b.add_theme_stylebox_override("normal", style)

func update_button_style(button:Button, bg_color):
	var style = button.get_theme_stylebox("normal")
	style.bg_color = bg_color
	button.add_theme_stylebox_override("normal", style)

func get_random_wordle():
	var file = FileAccess.open("res://wordle-list.txt", FileAccess.READ)
	var content = file.get_as_text(true)
	var lines = content.split("\n")
	randomize()
	var rng = RandomNumberGenerator.new()
	@warning_ignore("shadowed_variable")
	var index = rng.randi_range(0,lines.size()-1)
	return lines[index].to_upper()

func check_win():
	#Extract text from the last added row
	var entered_text = ""
	for button in buttons.slice(latest_row_index, latest_row_index + SIZE):
		entered_text += button.text
	print("Entered Text::", entered_text)
	# Colour row green
	# Always color the row
	for i in range(SIZE):
		var button = buttons[latest_row_index + i]
		if entered_text[i] == wordle[i]:
			update_button_style(button, Color.SEA_GREEN)
		elif entered_text[i] in wordle:
			update_button_style(button, Color.CHOCOLATE)
		else:
			update_button_style(button, Color.CRIMSON)
	if entered_text == wordle:
		print("You Win!")
		return
	else:
		# Update miss match colour
		var idx = 0
		for button in buttons.slice(latest_row_index, latest_row_index + SIZE):
			if entered_text[idx] == wordle[idx]:
				update_button_style(button, Color.SEA_GREEN)
			elif entered_text[idx] in wordle:
				update_button_style(button, Color.CHOCOLATE)
			elif entered_text[idx] not in wordle:
				update_button_style(button, Color.CRIMSON)
			idx += 1
	
