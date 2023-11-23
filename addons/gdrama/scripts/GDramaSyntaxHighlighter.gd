@tool
extends EditorSyntaxHighlighter
class_name GDramaSyntaxHighlighter


func _get_line_syntax_highlighting(line):
	var parser = GDramaParser.new()
	return parser.get_highlight(get_text_edit().get_line(line))


func _get_name():
	return "GDrama"


func _get_supported_languages():
	return PackedStringArray(["gdrama"])
