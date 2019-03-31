extends Object

class Expr extends Object:
	var immediate_class
	
	func _init(c = "Expr"):
		self.immediate_class = c

	func accept(visitor):
		return visitor.call(self.immediate_class, self)
		
	func get_immediate_class():
		return self.immediate_class

class Call extends Expr:
	var callee
	var paren
	var arguments
	
	func _init(callee, paren, arguments).("Call"):
		self.callee = callee
		self.paren = paren
		self.arguments = arguments
		
class Get extends Expr:
	var object
	var token_name
	
	func _init(object, token_name).("Get"):
		self.object = object
		self.token_name = token_name
		
class Set extends Expr:
	var object
	var token_name
	var value
	
	func _init(object, token_name, value).("Set"):
		self.object = object
		self.token_name = token_name
		self.value = value
		
class Super extends Expr:
	var keyword
	var method
	
	func _init(keyword, method).("Super"):
		self.keyword = keyword
		self.method = method
		
class This extends Expr:
	var keyword
	
	func _init(keyword).("This"):
		self.keyword = keyword
		
class Assign extends Expr:
	var token_name
	var value
	
	func _init(token_name, value).("Assign"):
		self.token_name = token_name
		self.value = value
		
#      "Logical  : Expr left, Token operator, Expr right",
class Logical extends Expr:
	var left
	var operator
	var right
	
	func _init(left, operator, right).("Logical"):
		self.left = left
		self.operator = operator
		self.right = right

class Binary extends Expr:
	var left
	var operator
	var right
	
	func _init(left, operator, right).("Binary"):
		self.left = left
		self.operator = operator
		self.right = right
		
class Unary extends Expr:
	var operator
	var right
	
	func _init(operator, right).("Unary"):
		self.operator = operator
		self.right = right
		
class Grouping extends Expr:
	var expression
	
	func _init(expression).("Grouping"):
		self.expression = expression
		
class Literal extends Expr:
	var value
	
	func _init(value).("Literal"):
		self.value = value
		
class Variable extends Expr:
	var token_name
	
	func _init(token_name).("Variable"):
		self.token_name = token_name