extends Object

var type
var lexeme
var literal
var line # Location

func _init(type, lexeme, literal, line):
	self.type = type
	self.lexeme = lexeme
	self.literal = literal
	self.line = line

func toString():
	return "\ntype: " + str(type) + "\nlexeme: " + str(lexeme) + "\nliteral: " + str(literal)

func is_token():
	return true