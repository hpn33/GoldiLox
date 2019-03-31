extends Node


const TYPE = preload("res://Data/Token.gd").TYPE
var output
var hadError
var hadRuntimeError

func _ready():
	output = get_tree().get_root().get_node("Lox/output")
	hadError = false
	hadRuntimeError = false

func error(line, message):
	report(line, "", message)
	
func report(line, where, message):
	output.text += "\nError: [line " + str(line) + "] Error " + where + " : " + message
	hadError = true
	
func syntax_error(token, message):
	if token.type == TYPE.EOF:
		report(token.line, " at end", message)
	else:
		report(token.line, " at '" + token.lexeme + "'", message)
	
func runTimeerror(error):
	print(error.getMessage() + "\n[line " + error.token.line + "]")
	hadRuntimeError = true