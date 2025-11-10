shader_type fog;

/* Smooth fog shader without dust effect */
uniform float base_density: hint_range(0, 1) = 0.5;
uniform vec3 base_color: source_color = vec3(1.0, 1.0, 1.0);
uniform float fade_out_height = 2.0;
uniform float fade_out_distance = 1.5;

// Optional: add very subtle variation (set to 0 for completely uniform fog)
uniform float noise_strength: hint_range(0, 1) = 0.1;
uniform vec3 noise_scale = vec3(0.5, 0.5, 0.5);
uniform vec3 noise_velocity = vec3(0.1, 0.0, 0.1);

vec3 hash(vec3 p) {
	p = vec3(dot(p,vec3(127.1,311.7, 74.7)),
			 dot(p,vec3(269.5,183.3,246.1)),
			 dot(p,vec3(113.5,271.9,124.6)));

	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(in vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f*f*(3.0-2.0*f);

    return mix( mix( mix( dot( hash( i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ), 
                          dot( hash( i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ), 
                          dot( hash( i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y),
                mix( mix( dot( hash( i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ), 
                          dot( hash( i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ), 
                          dot( hash( i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y), u.z );
}

void fog() {
	// Start with base density
	DENSITY = base_density;
	
	// Optional: add very subtle noise variation (can be disabled by setting noise_strength to 0)
	if (noise_strength > 0.0) {
		vec3 base_pos = WORLD_POSITION * noise_scale;
		float noise_value = noise(base_pos + TIME * noise_velocity);
		// Map noise from [-1,1] to [1-strength, 1+strength] for subtle variation
		float noise_multiplier = 1.0 + (noise_value * noise_strength);
		DENSITY *= noise_multiplier;
	}
	
	// Fade out with height (makes fog denser at ground level)
	DENSITY *= 1.0 - smoothstep(fade_out_height, fade_out_height + fade_out_distance, WORLD_POSITION.y);
	
	// Set fog color
	ALBEDO = base_color;
}