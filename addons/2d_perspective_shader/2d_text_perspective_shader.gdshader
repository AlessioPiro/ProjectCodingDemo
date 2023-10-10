shader_type canvas_item;

uniform float perspective : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    // Ottenere la posizione del pixel rispetto al centro del nodo
    vec2 center_offset = vec2(0.5, 0.5) - SCREEN_UV;
    
    // Applicare la prospettiva
    center_offset *= perspective;

    // Applicare la prospettiva al pixel
    vec2 uv = SCREEN_UV + center_offset;
    
    COLOR = texture(TEXTURE, uv);
}