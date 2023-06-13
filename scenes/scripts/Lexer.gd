
var start: int = 0
var current: int = 0
var line: int = 1 
var tokens: Array = []

func scan_tokens(code: String):
	while current < len(code):
		match code[current]:
			"<":
				tokens.append(Token.new("<", line, TokenType.LESS, null))
			">":
				tokens.append(Token.new(">", line, TokenType.GREATER, null))
				
			"(":
				tokens.append(Token.new("(", line, TokenType.LEFT_PARENTHESIS, null))
				
			")":
				tokens.append(Token.new(")", line, TokenType.RIGHT_PARENTHESIS, null))
				
			"{":
				tokens.append(Token.new("{", line, TokenType.LEFT_CURLY_BRACE, null))
				
			"}":
				tokens.append(Token.new("}", line, TokenType.RIGHT_CURLY_BRACE, null))
				
			"[":
				tokens.append(Token.new("[", line, TokenType.LEFT_BRACE, null))
				
			"]":
				tokens.append(Token.new("]", line, TokenType.RIGHT_BRACE, null))
				
			":":
                tokens.append(Token.new(":", line, TokenType.COLON, null))
                
            "\n":
                line++
             
                   
															
		
	
