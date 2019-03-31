extends Node

class Stmt extends Object:
	var immediate_class
	
	func _init(c = "Stmt"):
		self.immediate_class = c
		
	func accept(visitor):
		return visitor.call(self.immediate_class, self) # Next step is "resolve-expression"
		
	func get_immediate_class():
		return self.immediate_class
	
class Return extends Stmt:
	var keyword
	var value # KEEP TRACK OF THIS
	
	func _init(keyword, value).("Return"):
		self.keyword = keyword
		self.value = value


class If extends Stmt:
	var condition
	var thenBranch
	var elseBranch
	
	func _init(condition, thenBranch, elseBranch).("If"):
		self.condition = condition
		self.thenBranch = thenBranch
		self.elseBranch = elseBranch
		

class For extends Stmt:
	var initializer
	var condition
	var increment
	
	func _init(initializer = null, condition = null, increment = null).("For"):
		self.initializer = initializer
		self.condition = condition
		self.increment = increment
	
class While extends Stmt:
	var condition
	var body
	
	func _init(condition, body).("While"):
		self.condition = condition
		self.body = body
		
class Print extends Stmt:
	var expression
	
	func _init(expression).("Print"):
		self.expression = expression
		
		
class Expression extends Stmt:
	var expression
	
	func _init(expression).("Expression"):
		self.expression = expression 
		

class Block extends Stmt:
	var statements
	
	func _init(statements).("Block"):
		self.statements = statements
		
class Class extends Stmt:
	var token_name
	var superclass
	var methods = []
	
	func _init(token_name, superclass, methods).("Class"):
		self.token_name = token_name
		self.superclass = superclass
		self.methods = methods

class Var extends Stmt:
	var token_name
	var initializer
	
	func _init(token_name, initializer).("Var"):
		self.token_name = token_name
		self.initializer = initializer
	
class Function extends Stmt:
	var token_name
	var parameters
	var body
	
	func _init(token_name, parameters, body).("Function"):
		self.token_name = token_name
		self.parameters = parameters
		self.body = body