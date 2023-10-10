shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 2.0);
uniform vec4 target_color : source_color;

void fragment() {
    // Calcoliamo la posizione nel normale spazio di texture
    vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE;

    // Otteniamo il colore originale del texture
    vec4 original_color = texture(TEXTURE, uv);

    // Calcoliamo la luminosità del colore originale
    float brightness = (original_color.r + original_color.g + original_color.b) / 3.0;

    // Applichiamo il glow solo se la luminosità è sopra una certa soglia
    if (brightness > 0.5) {
        // Mescoliamo il colore originale con il colore target (il nostro effetto glow)
        COLOR.rgb = mix(original_color.rgb, target_color.rgb, glow_strength);
    } else {
        // Se la luminosità è bassa, manteniamo il colore originale
        COLOR.rgb = original_color.rgb;
    }

    // Manteniamo l'alpha invariato
    COLOR.a = original_color.a;
}
