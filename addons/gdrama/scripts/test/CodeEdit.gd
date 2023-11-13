extends CodeEdit


func _init():
	"""var parser = GDramaParser.new()
	print(get_text_edit().get_line(line))
	var colors = parser.get_highlight(get_text_edit().get_line(line))
	print(colors)
	return colors"""
	
	syntax_highlighter = GDramaSyntaxHighlighter.new()
