extends Node


const TOKEN = preload("res://Objects/Token.gd")
const TYPE = preload("res://Data/Token.gd").TYPE
var source
var tokens
var start
var current
var line

# This doesn't seem to work if stored in data/token.gd
var keywords = {"and": TYPE.AND, "class": TYPE.CLASS, "else": TYPE.ELSE, "false": TYPE.FALSE, "for": TYPE.FOR, "fun": TYPE.FUN, "if": TYPE.IF, "nil": TYPE.NIL,
"or": TYPE.OR, "print": TYPE.PRINT, "return": TYPE.RETURN, "super": TYPE.SUPER, "this": TYPE.THIS, "true": TYPE.TRUE, "var": TYPE.VAR, "while": TYPE.WHILE}

func _init(source):
	self.source = source
	self.tokens = []
	self.start = 0
	self.current = 0
	self.line = 1
	
func scanTokens():
	while !isAtEnd():
		start = current
		scanToken()
	
	# After all tokens are scanned, we append the EOF token here
	tokens.append(TOKEN.new(TYPE.EOF, "", null, line))
	return tokens
	
func isAtEnd():
	return current >= source.length()
	
func scanToken():
	var c = advance()
	match c:
		'(': addToken([TYPE.LEFT_PAREN])
		')': addToken([TYPE.RIGHT_PAREN])
		'{': addToken([TYPE.LEFT_BRACE])
		'}': addToken([TYPE.RIGHT_BRACE])
		',': addToken([TYPE.COMMA])
		'.': addToken([TYPE.DOT])
		'-': addToken([TYPE.MINUS])
		'+': addToken([TYPE.PLUS])
		';': addToken([TYPE.SEMICOLON])
		'*': addToken([TYPE.STAR])
		'!': addToken([TYPE.BANG_EQUAL]) if match_next('=') else addToken([TYPE.BANG])
		"=": addToken([TYPE.EQUAL_EQUAL]) if match_next('=') else addToken([TYPE.EQUAL])
		'<': addToken([TYPE.LESS_EQUAL]) if match_next('=') else addToken([TYPE.LESS])
		'>': addToken([TYPE.GREATER_EQUAL]) if match_next('=') else addToken([TYPE.GREATER])
		'/': 
			if match_next('/'):
				while peek() != '\n' and !isAtEnd():
					advance()
			else:
				addToken([TYPE.SLASH])
		' ', '\t', '\r': return
		'\n': line += 1
		'"': 
			string() # String is probably the issue, we aren't advancing far enough?
		_:
			if isDigit(c):
				number()
	
			elif isAlpha(c):
				identifier()
			else:
				Error.error(line, "unexpected character")

func identifier():
	while isAlphaNumeric(peek()):
		advance()
		
	var end = current - start
	var text = source.substr(start, end)
	var type = keywords[text] if keywords.has(text) else TYPE.IDENTIFIER
	addToken([type])

	
func isAlpha(c):
	return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_'
	
func isAlphaNumeric(c):
	return isAlpha(c) or isDigit(c)
	
func isDigit(c):
	return c >= "0" and c <= "9"
	
func number():
	while isDigit(peek()):
		advance()
		
	# Look for a fractional part (ie decimal)
	if peek() == '.' and isDigit(peekNext()):
		# Consume the '.'
		advance()
	
		while isDigit(peek()):
			advance()
	
	# Another substr. Be careful
	var end = current - start
	addToken([TYPE.NUMBER, float(source.substr(start, end))])
	
func peekNext():
	if current + 1 >= source.length():
		return '\\0'
	return source[current + 1]
	
func string():
	while peek() != '"' and !isAtEnd():
		if peek() == '\n':
			line += 1
		advance()
	
	# Unterminated string
	if isAtEnd():
		Error.error(line, "Unterminated string.")
		return

	# The closing "
	advance()

	# Trimming the " " off both sides
	var end = current - start
	var value = source.substr(start + 1, end -2)
	addToken([TYPE.STRING, value])
	
func peek():
	if isAtEnd():
		return '\\0'
	return source[current]
	
func advance():
	current += 1
	return source[current-1]
	
func addToken(args):
	var literal = null
	# Get type and literal, set literal to null if no type
	var type = args[0]
	if args.size() > 1:
		literal = args[1]
	var end = current - start
	var text = source.substr(start, end)
	tokens.append(TOKEN.new(type, text, literal, line))
	
func match_next(expected):
	if isAtEnd():
		return false
	if source[current] != expected:
		return false
	current += 1
	return true
