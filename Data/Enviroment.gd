extends Node

class enviroment:
	var enclosing = null
	var values = {}
	
	func _init(enclosing):
		self.enclosing = enclosing
	
	func define(title, value):
		values[title] = value
		
	func getAt(distance, lexeme):
		return ancestor(distance).values[lexeme] # May be wrong syntax
	
	func assignAt(distance, token_name, value):
		ancestor(distance).values[token_name.lexeme] = value
	
	func ancestor(distance):
		var i = 0
		var enviroment = self
		while i < distance:
			enviroment = enviroment.enclosing
			i += 1
		return enviroment

	func get(token):
		if values.has(token.lexeme):
			return values[token.lexeme]
		if enclosing != null:
			return enclosing.get(token)
		print(token, " undefined variable '" + token.lexeme + "'.")
	#	Error.runTimeerror([token, "Undefined variable '" + token.lexeme + "'."])
	
	
	func assign(token_name, value):
		if values.has(token_name.lexeme): #
			values[token_name.lexeme] = value
			return
		if enclosing != null:
			enclosing.assign(token_name, value)
			return
		return
	#	  throw new RuntimeError(name,                     
	##        "Undefined variable '" + name.lexeme + "'.");
	