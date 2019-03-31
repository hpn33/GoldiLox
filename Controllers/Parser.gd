extends Node

const TYPE = preload("res://Data/Token.gd").TYPE
const Expr = preload("res://Objects/Expr.gd")
const Stmt = preload("res://Objects/Stmt.gd")
var tokens = []
var current = 0

func _init(tokens):
	self.tokens = tokens
	
func parse():
	var statements = []
	while !isAtEnd():
		statements.append(declaration())
	return statements
	
func expression():
	return assignment()

func declaration():
	if _match([TYPE.VAR]):
		return varDeclaration()
	if _match([TYPE.CLASS]):
		return classDeclaration()
	if _match([TYPE.FUN]):
		return function("function")
	else:
		return statement()
		
func classDeclaration():
	var superclass = null
	var token_name = consume(TYPE.IDENTIFIER, "Expect class name.")
	if _match([TYPE.LESS]):
		consume(TYPE.IDENTIFIER, "Expect superclass name.")
		superclass = Expr.Variable.new(previous())
	consume(TYPE.LEFT_BRACE, "Expect '{' before class body.")
	var methods = []
	while !check(TYPE.RIGHT_BRACE) and !isAtEnd():
		methods.append(function("method"))
	consume(TYPE.RIGHT_BRACE, "Expect '}' after class body")
	return Stmt.Class.new(token_name, superclass, methods)
		
# Modern version that is intended to handle errors
#func declaration():
#	if _match([TYPE.VAR]):
#		var value = varDeclaration()
#		if value.get_immediate_class() == "ParseError":
#			synchronize()
#			return null
#		return value
#	var val = statement()
#	if val.get_immediate_class() == "ParseError":
#		synchronize()
#		return null
#	return val
	# Errors would be thrown here, using "Synchronize" to make sure the token stream doesn't crash
	
func statement():
	if _match([TYPE.PRINT]):
		return printStatement()
	if _match([TYPE.RETURN]):
		return returnStatement() # Returning to who?
	if _match([TYPE.LEFT_BRACE]):
		return Stmt.Block.new(block()) # ????
	if _match([TYPE.IF]):
		return ifStatement()
	if _match([TYPE.WHILE]):
		return whileStatement()
	if _match([TYPE.FOR]):
		return forStatement()
	return expressionStatement()

func forStatement():
	consume(TYPE.LEFT_PAREN, "Expect '(' after 'for'.")
	var initializer = null
	if _match([TYPE.SEMICOLON]):
		initializer = null
	elif _match([TYPE.VAR]):
		initializer = varDeclaration() # Might be it
	else:
		initializer = expressionStatement() # Re-Assignment
	var condition = null;
	if !check(TYPE.SEMICOLON):
		condition = expression()
	consume(TYPE.SEMICOLON, "Expect ';' after loop condition.")
	var increment = null;
	if !check(TYPE.RIGHT_PAREN):
		increment = expression()
	consume(TYPE.RIGHT_PAREN, "Expect ')' after for clauses.")
	var body = statement()
	if increment != null:
		body = Stmt.Block.new([body, Stmt.Expression.new(increment)])
	if condition == null:
		condition = Expr.Literal.new(true) # Infinite loop?
	body = Stmt.While.new(condition, body)
	if initializer != null:
		body = Stmt.Block.new([initializer, body])
	return body

func ifStatement():
	consume(TYPE.LEFT_PAREN, "Expect '(' after 'if'.")
	var condition = expression()
	consume(TYPE.RIGHT_PAREN, "Expect ')' after if condition.")
	var thenBranch = statement()
	var elseBranch = null;
	if _match([TYPE.ELSE]):
		elseBranch = statement()
	return Stmt.If.new(condition, thenBranch, elseBranch)
	
	
func printStatement():
	var value = expression()
	consume(TYPE.SEMICOLON, "Expect ';' after value.") # This may be the issue?
	return Stmt.Print.new(value)
	
func returnStatement():
	var keyword = previous()
	var value = null;
	if !check(TYPE.SEMICOLON):
		value = expression()
	consume(TYPE.SEMICOLON, "Expect ':' after return value.")
	return Stmt.Return.new(keyword, value)

func varDeclaration():
	var token_name = consume(TYPE.IDENTIFIER, "Expect variable name.")
	var initializer = null
	if _match([TYPE.EQUAL]):
		initializer = expression()
	consume(TYPE.SEMICOLON, "Expect ';' after variable declaration.")
	return Stmt.Var.new(token_name, initializer)
	
func whileStatement():
	consume(TYPE.LEFT_PAREN, "Expect '(' after 'while'.")
	var condition = expression()
	consume(TYPE.RIGHT_PAREN, "Expect ')' after condition.")
	var body = statement()
	return Stmt.While.new(condition, body)
	
func expressionStatement():
	var expr = expression()
	consume(TYPE.SEMICOLON, "Expect ';' after expression.")
	return Stmt.Expression.new(expr)
	
func function(kind):
	var token_name = consume(TYPE.IDENTIFIER, "Expect " + kind + " name.")
	consume(TYPE.LEFT_PAREN, "Expect '(' after " + kind + " name.")
	var parameters = []
	while !check(TYPE.RIGHT_PAREN):
		if parameters.size() >= 8:
			error(peek(), "Cannot have more than 8 parameters")
		parameters.append(consume(TYPE.IDENTIFIER, "Expect parameters name."))
		if not _match([TYPE.COMMA]):
			break
	consume(TYPE.RIGHT_PAREN, "Expect ')' after parameters.")
	consume(TYPE.LEFT_BRACE, "Expect '{' before " + kind + "body.")
	var body = block()
	return Stmt.Function.new(token_name, parameters, body)
		
func block():
	var statements = []
	while !check(TYPE.RIGHT_BRACE) and !isAtEnd(): # !IsAtEnd might be redundant with the bool in check
		statements.append(declaration())
	
	consume(TYPE.RIGHT_BRACE, "Expect '}' after block.")
	return statements
	
func assignment():
#	var expr = equality()
	var expr = Or() # or is reserved
	if _match([TYPE.EQUAL]):
		var equals = previous()
		var value = assignment() # Be wary of infinite loops
#		if expr.get_immediate_class() == "Variable":
		if expr is Expr.Variable:
			var token_name = expr.token_name # Think this is right?
			return Expr.Assign.new(token_name, value) # If we get an error, we haven't returned this properly
		elif expr is Expr.Get:
#			var get = expr.expr # They cast the Expression to an Expr get but GDScript does the for us already
			return Expr.Set.new(expr.object, expr.token_name, value)
		else:
			Error.error(equals, "Invalid assignment target")
	return expr # I don't think we reach here? 

func Or():
	var expr = And() # and is reserved
	
	while _match([TYPE.OR]):
		var operator = previous()
		var right = And()
		expr = Expr.Logical.new(expr, operator, right)
	return expr

func And():
	var expr = equality()
	
	while _match([TYPE.AND]):
		var operator = previous()
		var right = equality()
		expr = Expr.Logical.new(expr, operator, right)
	return expr

func equality():
	var expr = comparison()
	
	while _match([TYPE.BANG_EQUAL, TYPE.EQUAL_EQUAL]):
		var operator = previous()
		var right = comparison()
		expr = Expr.Binary.new(expr, operator, right)
	return expr
	
func comparison():
	var expr = addition()
	
	while _match([TYPE.GREATER, TYPE.GREATER_EQUAL, TYPE.LESS, TYPE.LESS_EQUAL]):
		var operator = previous()
		var right = addition()
		expr = Expr.Binary.new(expr, operator, right)
	return expr
	
func addition():
	var expr = multiplication()
	
	while _match([TYPE.MINUS, TYPE.PLUS]):
		var operator = previous()
		var right = multiplication()
		expr = Expr.Binary.new(expr, operator, right)
	return expr
	
func multiplication():
		var expr = unary()
		while _match([TYPE.SLASH, TYPE.STAR]):
			var operator = previous()
			var right = unary()
			expr = Expr.Binary.new(expr, operator, right)
		return expr                                           
	
func unary():
	if _match([TYPE.BANG, TYPE.MINUS]):
		var operator = previous()
		var right = unary()
		return Expr.Unary.new(operator, right)
	
	return call()

func finishCall(callee):
	var arguments = []
	
	# If the next token is a right side brace, we know the arguments are finished
	while !check(TYPE.RIGHT_PAREN):
		if arguments.size() >= 8:
			error(peek(), "Cannot have more than 8 arguments")
		# If it isn't a right brace, there must be an argument inside of it
		arguments.append(expression())
		# We check for a comma, if there isn't one, we know there are no more arguments to add
		if not _match([TYPE.COMMA]):
			# This should work like a do (body) while (bool) in Java.
			break
	
	var paren = consume(TYPE.RIGHT_PAREN, "Expect ')' after arguments.")
	return Expr.Call.new(callee, paren, arguments)
		

func call():
	var expr = primary()
	while (true):
		if _match([TYPE.LEFT_PAREN]):
			expr = finishCall(expr)
		elif _match([TYPE.DOT]):
			var token_name = consume(TYPE.IDENTIFIER, "Expect property name after '.'.")
			expr = Expr.Get.new(expr, token_name)
		else:
			break
	return expr

func primary():
	if _match([TYPE.FALSE]): return Expr.Literal.new(false)
	if _match([TYPE.TRUE]): return Expr.Literal.new(true)
	if _match([TYPE.NIL]): return Expr.Literal.new(null)
	if _match([TYPE.THIS]): return Expr.This.new(previous())
	# Literal is a reference to the TOKEN CLASS, not the Expression Classes
	
	if _match([TYPE.NUMBER, TYPE.STRING]):
		return Expr.Literal.new(previous().literal)
	if _match([TYPE.SUPER]):
		var keyword = previous()
		consume(TYPE.DOT, "Expect '.' after ' super'.")
		var method = consume(TYPE.IDENTIFIER, "Expect superclass method name.")
		return Expr.Super.new(keyword, method)
	if _match([TYPE.IDENTIFIER]):
		return Expr.Variable.new(previous())
	if _match([TYPE.LEFT_PAREN]):
		var expr = expression()
		consume(TYPE.RIGHT_PAREN, "Expect ')' after expression.")
		return Expr.Grouping.new(expr)
		
	return error(peek(), "Expect Expression:")
		
                                          
func _match(Types):
	# Underscore for method so we don't run into naming conflicts with GDScript Keywords
	for type in Types:
		if check(type):
			advance()
			return true
	return false
	
func consume(type, message):
	if check(type):
		return advance() # This might be failing?
	return error(peek(), message)
	
func check(type):
	if isAtEnd():
		return false
	return peek().type == type

func advance():
	if !isAtEnd():
		current +=1
	return previous()
	
func isAtEnd():
	return peek().type == TYPE.EOF
	
func peek():
	return tokens[current]
	
func previous():
	return tokens[current-1]
	
func error(token, message):
	Error.syntax_error(token, message)
	return ParseError.new()

func synchronize():
	advance()
	
	while !isAtEnd():
		if previous().type == TYPE.SEMICOLON:
			return
			
		match peek().type:
			TYPE.CLASS: continue
			TYPE.FUN: continue
			TYPE.VAR: continue
			TYPE.FOR: continue
			TYPE.IF: continue
			TYPE.WHILE: continue
			TYPE.PRINT: continue
			TYPE.RETURN: return
		
		advance()
			
class ParseError:
	var tokens
	
	func _init():
		pass
		
	func get_immediate_class():
		return "ParseError"