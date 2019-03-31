extends Node

const Scanner = preload("res://Controllers/Scanner.gd")
const Parser = preload("res://Controllers/Parser.gd")
const Resolver = preload("res://Controllers/Resolver.gd")

# Interpreter is static so it can hold state
onready var Interpreter = preload("res://Controllers/Interpreter.gd").new()
var output
var input

func _ready():
	self.output = $output
	self.input = $input
	input.connect("text_entered", self, "_initial_input")
	
func _initial_input(args):
	args = args.split(" ")
	input.text = ""
	
	if args[0] != "jlox":
		output.text += "\nError: usage jlox [script]"
	elif args.size() == 2:
		# This prompt checks for "jlox" and "script_name"
		# Then runs the named script
		runFile(args[1])
	else:
		runPrompt()
		output.text += "\n REPL Initiated"

		
func runFile(path):
	input.text = ""
	var file = File.new()
	file.open(path, file.READ)
	var content = file.get_as_text()
	file.close()
	run(content)
#	if Error.hadError:
#		get_tree().quit()
#	if Error.hadRuntimeError:
#		get_tree().quit()

func runPrompt():
	# runPrompt just re-connects signals, so input goes directly into run from input
	input.disconnect("text_entered", self, "_initial_input")
	input.connect("text_entered", self, "run")
	
func run(source):
	input.text = ""
	var scanner = Scanner.new(source)
	var tokens = scanner.scanTokens() # Seems to be having trouble reading?
	var parser = Parser.new(tokens)
	var statements = parser.parse()
	if Error.hadError:
		return
#
	var resolver = Resolver.new(Interpreter)
	resolver.resolve_loop(statements)

	if Error.hadError:
		return
	Interpreter.interpret(statements)

	scanner.queue_free()
	parser.queue_free()
	input.text = ""