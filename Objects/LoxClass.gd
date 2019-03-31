extends Node

const Callable = preload("res://Objects/LoxCallable.gd")

class LoxClass extends Callable:
	var title
	var superclass
	var methods

	func _init(title, superclass, methods):
		self.title = title
		self.superclass = superclass
		self.methods = methods

	func Call(interpreter, arguments):
		var instance = Instance.new(self)
		
		if methods.has("init"):
			var initializer = methods["init"]
			if initializer != null:
				initializer.bind(instance).Call(interpreter, arguments)
				
		return instance

	func toString():
		return self.title

	func arity():
		if methods.has("init"):
			var initializer = methods["init"]
			if initializer != null:
				return initializer.arity()
		return 0
		
	func findMethod(instance, lexeme):
		if methods.has(lexeme):
			return methods[lexeme].bind(instance) # This may not work because GDScript funcs aren't class funcs
		if superclass != null:
			return superclass.findMethod(instance, lexeme)
		return null
		
	class Instance:
		# Instance is stuffed in here as a subclass other we get real weird errors
		var klass
		var fields
		
		func _init(klass):
			self.klass = klass
			self.fields = {}
			
		func toString():
			return klass.title + " instance"
			
		func get(token_name):
			if fields.has(token_name.lexeme):
				return fields[token_name.lexeme]
			var method = klass.findMethod(self, token_name.lexeme)
			if method != null:
				return method
			# runtime error
			print(token_name, " Undefined property ' " + token_name.lexeme + "'.")
			
		func set(token_name, value):
			fields[token_name.lexeme] = value
			
		


