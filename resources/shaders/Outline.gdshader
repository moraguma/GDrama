/* 
Rainbow outline by @Farfalk and @ThePadDev, And Edit for @LURGX in 2022

Apply to canvas items with transparent backgrounds.
Check that there is sufficient transparent background space for the outline!

CC0 License (but citation is welcome <3)
All code is property of @Farfalk and @ThePadDev
Thanks for shader and I'm a newbie with shaders 
*/

shader_type canvas_item;

uniform bool rainbow  = false; //Activate the rainbow or select you color
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);//color line
uniform float line_scale : hint_range(0, 20) = 1.2;    // thickness of the line
uniform float frequency : hint_range(0.0, 2.0) = 0.5;  // frequency of the rainbow
uniform float light_offset : hint_range(0.00001, 1.0) = 0.5;   // this offsets all color channels;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * line_scale;
	
	float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
	outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
	outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
	outline = min(outline, 1.0);
	
	vec4 animated_line_color = vec4(light_offset + sin(2.0*3.14*frequency*TIME),
							   light_offset + sin(2.0*3.14*frequency*TIME + radians(120.0)),
							   light_offset + sin(2.0*3.14*frequency*TIME + radians(240.0)),
							   alpha);
	
	vec4 color = texture(TEXTURE, UV);
	if (rainbow == true){//if rainbow is activated
		COLOR = mix(color, animated_line_color, outline - color.a);
	}
	if (rainbow == false){//if rainbow not is activated and you pick a color
		COLOR = mix(color, line_color , outline - color.a);
	}
}