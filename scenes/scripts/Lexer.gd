class_name Lexer


func get_token(name: String, line: int):
	if name.is_valid_float():
		return Token.new(name, line, TokenType.NUMBER, float(name))
	else:
		return Token.new(name, line, TokenType.STRING, name)


static func scan_tokens(code: String) -> Array:
	var pos: int = 0
	var line: int = 0
	var tokens: Array[Token] = []
	var total_tokens = 0
	var current = ""
	
	while pos < len(code):
		match code[pos]:
			"<":
				tokens.append(Token.new("<", line, TokenType.LESS, null))
			">":
				tokens.append(Token.new(">", line, TokenType.GREATER, null))
			"{":
				tokens.append(Token.new("{", line, TokenType.LEFT_CURLY_BRACE, null))
			"}":
				tokens.append(Token.new("}", line, TokenType.RIGHT_CURLY_BRACE, null))
			"\"":
				tokens.append(Token.new("}", line, TokenType.RIGHT_CURLY_BRACE, null))
			":":
				tokens.append(Token.new(":", line, TokenType.COLON, null))
			"\n":
				line += 1
			" ":
				if tokens[-1].type == TokenType.QUOTES or tokens[-1].type == TokenType.LEFT_CURLY_BRACE:
					current += " "
				elif current != "":
					if tokens[-1].type == TokenType.LESS:
						match current:
							"beat":
								tokens.append(Token.new("beat", line, TokenType.BEAT, null))
							"choice":
								tokens.append(Token.new("beat", line, TokenType.CHOICE, null))
					else:
						tokens.append(get_identifier())
			"\t":
				pass
		
		pos += 1
	
	return tokens
