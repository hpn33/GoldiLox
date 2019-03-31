extends Node

const ENVIROMENT = preload("res://Data/Enviroment.gd").enviroment
const TYPE = preload("res://Data/Token.gd").TYPE
const Callable = preload("res://Objects/LoxCallable.gd")
const LoxClass = preload("res://Objects/LoxClass.gd").LoxClass


var globals = ENVIROMENT.new(null)
var enviroment = globals # Not always globals?
var locals = {}

# Working with retvals:
signal RETURN
var exited_early = false

func _init():
	pass
#	self.globals.define('Clock', Callable.Clock.new())


func interpret(statements):
	for statement in statements:
		# Not pretty but hopefully it will
		if exited_early:
			return
		execute(statement)
	# They throw an error here somewhere. Need to figure out a proper way to replicate it
	
func execute(statement):
	statement.accept(self)

func resolve(expression, depth):
	locals[expression] = depth

func Block(statement):
	# We are passing in a NEW enviroment, and passing our *current* enviroment to its constructor so it can
	# check one level up
	executeBlock(statement.statements, ENVIROMENT.new(self.enviroment))
	return null
	
func Class(statement):
	var superclass = null
	if statement.superclass != null:
		superclass = evaluate(statement.superclass)
		if !superclass is LoxClass:
			Error.error(statement.superclass.token_name, "Superclass must be a class")
	enviroment.define(statement.token_name.lexeme, null)
	if statement.superclass != null:
		enviroment = ENVIROMENT.new(enviroment)
		enviroment.define("super", superclass)
	var methods = {} # Resolver counterpart may require key access, rather than array loop
	for method in statement.methods:
		# May be an issue here?
		var function = Callable.Function.new(method, enviroment, method.token_name.lexeme == "init")
		methods[method.token_name.lexeme] = function
	var klass = LoxClass.new(statement.token_name.lexeme, superclass, methods) # May need to revist this
	if superclass != null:
		enviroment = enviroment.enclosing
	enviroment.assign(statement.token_name, klass)
	return null
	

	
func executeBlock(statements, enviroment):
	# We're storing the current enviroment into previous enviroment so we don't lose it
	var previous_enviroment = self.enviroment
	
	# This is wrapped in a try block in the tutorial
	# We go into the new enviroment scope
	self.enviroment = enviroment
	for statement in statements:
		# We're hitting this one repeatedly here? 
		if self.exited_early:
			break
		# These are all being executed in the new scope
		execute(statement)
		
	# Once finished we exit the scope back up one
	self.enviroment = previous_enviroment
	
#func visit():
#	# Hopefully works as intended. May require look over
#	return preload("res://Objects/VisitorInterface.gd")
	
func Literal(expr):
	return expr.value
	
func Logical(expression):
	var left = evaluate(expression.left)
	if expression.operator.type == TYPE.OR:
		if isTruthy(left):
			return left
	# I know {} but screw } else {
	else:
		if !isTruthy(left):
			return left
	
	return evaluate(expression.right)
	
func Set(expression):
	var object = evaluate(expression.object)
	
	if not object is LoxClass.Instance:
		print(expression.token_name, "Only instances have fields")
	var value = evaluate(expression.value)
	object.set(expression.token_name, value)
	return value
	
func Super(expression):
	var distance = locals[expression] # May need to do a check?
	var superclass = enviroment.getAt(distance, "super")
	var object = enviroment.getAt(distance - 1, "this")
	var method = superclass.findMethod(object, expression.method.lexeme)
	if method == null:
		Error.runTimeerror(expression.method, "Undefined property '" + expression.method.lexeme + "',")
	return method
	
func This(expression):
	return lookUpVariable(expression.keyword, expression)
	
func Grouping(expr):
	return evaluate(expr.expression)
	
func evaluate(expr):
	# This shouldn't be calling a reference?
	return expr.accept(self)
	
func Expression(statement):
	evaluate(statement.expression)
	return null
	
func Function(statement):
	var function = Callable.Function.new(statement, self.enviroment, false)
	enviroment.define(statement.token_name.lexeme, function)
#	var function = Callable.Function.new(statement, self.enviroment)
#
##		func assignAt(distance, token_name, value):	// What we want to implement?
#	var distance
#	if locals.has(statement):
#		distance = locals[statement]
#		enviroment.assignAt(distance, statement.token_name, function) # Maybe Errors
#	else:
#		enviroment.assign(statement.token_name, function)
##		enviroment.define(statement.token_name.lexeme, function)
#	return null
	
#	var distance = locals[expr]
#	if distance != null:
#		enviroment.assignAt(distance, expr.token_name, value)
#	else:
#		globals.assign(expr.token_name, value)
##	enviroment.assign(expr.token_name, value)
#	return value
#
	
func If(statement):
	if isTruthy(evaluate(statement.condition)):
		execute(statement.thenBranch)
	elif statement.elseBranch != null:
		execute(statement.elseBranch)
	return null
	
func Print(statement):
	var value = evaluate(statement.expression)
	print(stringify(value))
	return null

func Return(statement):
	var value = null
	if statement.value != null:
		value = evaluate(statement.value)
	# Emulating a throw
	self.exited_early = true
	emit_signal("RETURN", value)
	
func Var(statement):
	var value = null
	if statement.initializer != null:
		value = evaluate(statement.initializer)
	# The triple dot access may be wrong but not sure
	enviroment.define(statement.token_name.lexeme, value)
	return null
	
func While(statement):
	while isTruthy(evaluate(statement.condition)):
		execute(statement.body)
	return null

func Assign(expr):
	var value = evaluate(expr.value)
	var distance
	if locals.has(expr):
		distance = locals[expr]
		enviroment.assignAt(distance, expr.token_name, value)
	else:
		globals.assign(expr.token_name, value)
	return value
	
func Unary(expr):
	var right = evaluate(expr.right)
	
	match expr.operator.type:
		TYPE.MINUS:
			checkNumberOperand(expr.operator, right);
			return -float(right)
		TYPE.BANG:
			return !isTruthy(right)
	return null
	
func Variable(expr):
	return lookUpVariable(expr.token_name, expr);            
#	return enviroment.get(expr.token_name)

func lookUpVariable(token_name, expression):
	var distance = null
	if locals.has(expression):
		distance = locals[expression]
	if distance != null:
		return enviroment.getAt(distance, token_name.lexeme)
	else:
		return globals.get(token_name)

func isTruthy(object):
	if object == null: 
		return false
	if typeof(object) == TYPE_BOOL: 
		return bool(object)
	return true

func Binary(expr):
	var left = evaluate(expr.left)
	var right = evaluate(expr.right) # left????
	match expr.operator.type:
		TYPE.GREATER:
			checkNumberOperands(expr.operator, left, right)
			return float(left) > float(right)
		TYPE.GREATER_EQUAL:
			checkNumberOperands(expr.operator, left, right)
			return float(left) >= float(right)
		TYPE.LESS:
			checkNumberOperands(expr.operator, left, right)
			return float(left) < float(right)
		TYPE.LESS_EQUAL:
			checkNumberOperands(expr.operator, left, right)
			return float(left) <= float(right)
		TYPE.BANG_EQUAL: return !isEqual(left, right)
		TYPE.EQUAL_EQUAL: return isEqual(left, right)
		TYPE.MINUS:
			checkNumberOperands(expr.operator, left, right)
			return float(left) - float(right)
		TYPE.PLUS:
			if typeof(left) == TYPE_REAL and typeof(right) == TYPE_REAL:
				return float(left) + float(right)
			elif typeof(left) == TYPE_STRING and typeof(right) == TYPE_STRING:
				return left + right
			RuntimeError.new(expr.operator, "Operands must be two numbers OR two strings")
		TYPE.SLASH:
			checkNumberOperands(expr.operator, left, right)
			return float(left) / float(right)
		TYPE.STAR:
			checkNumberOperands(expr.operator, left, right)
			return float(left) * float(right)
		
	# Unreachable
	return null
	
func Call(expression):
	var callee = evaluate(expression.callee)
	var arguments = []
	for argument in expression.arguments:
		arguments.append(evaluate(argument))
		
#	if not callee is Callable:
#	if not callee.immediate_class == "Callable" or not callee.immediate_class == "Function":
#		print('class is ', callee.immediate_class, ' line 238 Interpreter')
#		throw new RuntimeError(expr.paren, "Can only call functions and classes.")

	var function = callee
	if arguments.size() != function.arity():
		print(expression.paren, "Expected " + str(function.arity()) + " arguments but got " + str(arguments.size()) + ".")
	return function.Call(self, arguments) # Pretty sure this is a class? Adding a small interpreter?

func Get(expression):
	var object = evaluate(expression.object)
	if object is LoxClass.Instance: # May need to access this from somewhere? Maybe through LoxClass.Instance instead
		return object.get(expression.token_name) # CAREFUL HERE?
	print(expression.token_name, "only instances have properties")
	# RuntimeError(expression.token_name, "Only instances have properties")

func isEqual(a, b):
	# nil is only equal to nil
	if a == null and b == null: return true
	if a == null: return false
	
	return a == b
	
func stringify(object):
	if typeof(object) == TYPE_NIL: return "nil"
	
	if typeof(object) == TYPE_REAL:
		# toString may not have been implemented?
		var text = str(object)
		if text.ends_with(".0"):
			text = text.subst(0, text.length() -2)
		return text
	
	if typeof(object) == TYPE_STRING:
		return object
	return object.toString()

func checkNumberOperand(operator, operand):
	if typeof(operand) == TYPE_REAL: 
		return
	else:
		# Throwing an error
		RuntimeError.new(operator, "Operand must be a number")

func checkNumberOperands(operator, left, right):
	if typeof(left) == TYPE_REAL and typeof(right) == TYPE_REAL:
		return
	# This may conflict with GDScript ints unless we were already converting them?
	RuntimeError.new(operator, "Operands must be numbers")

class RuntimeError:
	var token
	
	func _init(token, message):
		# Super invoke here?
		# super_init(message)
		print(message)
		self.token = token