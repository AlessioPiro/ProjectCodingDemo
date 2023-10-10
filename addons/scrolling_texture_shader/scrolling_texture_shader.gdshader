shader_type spatial;
render_mode unshaded;

uniform vec2 speed_and_direction = vec2(0.25, 0.00);
uniform vec2 scale = vec2(1.0);
uniform bool flip = false;
uniform sampler2D albedo: source_color;
uniform float alpha_multiplier = 1.0;

void fragment() {
	//Calcolo delle cordinate UV in base a direzione, velocità e scala
	vec2 uv = UV * scale - speed_and_direction * TIME;
	//Inverte le coordinate UV se "flip" è true
	if (flip) { uv = 1.0 - uv; }
	//Assegna il colore al pixel corrente
	vec4 text_color = texture(albedo, uv);
	
	// Modifica l'opacità del colore dell'albedo
    text_color.a *= alpha_multiplier;
	
	//Assegna colore e alfa al pixel corrente
	ALBEDO = vec3(text_color.rgb);
	ALPHA = text_color.a;
}