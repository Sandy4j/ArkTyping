shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_softness : hint_range(0.1, 2.0) = 0.8;
uniform vec4 vignette_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 screen_color = texture(TEXTURE, UV);

	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	
	float vignette = smoothstep(vignette_softness, vignette_softness - 0.5, dist);
	vignette = 1.0 - vignette;
	vec3 final_color = mix(screen_color.rgb, vignette_color.rgb, vignette * vignette_intensity);
	float final_alpha = vignette * vignette_intensity * vignette_color.a;
	
	// Apply vignette effect by multiplying with intensity
	float alpha = vignette * vignette_intensity;
	COLOR = vec4(vignette_color.rgb, alpha);
}