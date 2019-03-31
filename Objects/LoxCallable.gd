extends Node

class Callable extends Object:
	var parameters = []
	var immediate_class
	
	func _init(c = "Callable"):
		self.immediate_class = c
		
	func accept(visitor):
		print('visitor is, ', visitor, ' LoxCallable line 11')
		visitor.call(self.current_class, self)
		
class Clock extends Callable:
	var token_name = "Clock"
	
	func _init().("Function"):
		self.parameters = 0
	
	func arity():
		return 0
		
	func Call(interpreter, arguments): # Not sure if we need to add this?
		return float(OS.get_system_time_secs())
		
	func toString():
		return "<native fn>"

class Bind:
	# Helper for Function
	static func delegate(declaration, enviroment, isInitializer):
		return load("res://Objects/LoxCallable.gd").Function.new(declaration, enviroment, isInitializer)

class Function extends Callable:
	
	var declaration
	var closure
	var isInitializer 
	
	# We store the return value to return here, defaults to null in call
	var returnValue
	
	func _init(declaration, closure, isInitializer).("Function"):
		self.declaration = declaration
		self.closure = closure # Where do we define this?
		self.isInitializer = isInitializer
		
	func Call(interpreter, arguments):
		# We initialize the return value to null
		self.returnValue = null
#		ifbool is_connected( String signal, Object target, String method ) c
		if not interpreter.is_connected("RETURN", self, "setReturnValue"):
			interpreter.connect("RETURN", self, "setReturnValue")
		var enviroment = interpreter.ENVIROMENT.new(self.closure)
		for i in range(declaration.parameters.size()):
			enviroment.define(declaration.parameters[i].lexeme, arguments[i])
			
		# The interpreter will break itself via boolean check
		# So if we hit an early return, the interpreter will set its boolean and break its execution loop
		interpreter.executeBlock(declaration.body, enviroment)
		
		# Note to others, all functions use the SAME interpreter but within different enviroments. Therefore we have to reset our early exit boolean back to false
		# from here
		interpreter.exited_early = false
		
		# One shot is not working here?
		# We ALWAYS return something, it will default to nil/null unless otherwise set.
		if isInitializer:
			return closure.getAt(0, "this")
		
		return returnValue
		
	func bind(instance):
		var enviroment = load("res://Data/Enviroment.gd").enviroment.new(closure)
		enviroment.define("this", instance)
		
		# Can't do it from inside itself, not until at least 3.1
		return Bind.delegate(declaration, enviroment, isInitializer)
		
	func setReturnValue(value):
		self.returnValue = value
		
	func arity():
		return declaration.parameters.size()
		
	func toString():
		return "<fn " + declaration.token_name.lexeme + ">"