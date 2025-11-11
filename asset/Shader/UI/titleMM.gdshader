shader_type canvas_item;

uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform float pulse_intensity : hint_range(0.0, 2.0) = 0.5;
uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform float glow_size : hint_range(0.0, 0.1) = 0.02;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
    float glow_strength = pulse * pulse_intensity;
    
    vec4 glow = vec4(0.0);
    float samples = 0.0;
    
    for(float x = -1.0; x <= 1.0; x += 1.0) {
        for(float y = -1.0; y <= 1.0; y += 1.0) {
            vec2 offset = vec2(x, y) * glow_size;
            glow += texture(TEXTURE, UV + offset);
            samples += 1.0;
        }
    }
    
    glow /= samples;
    glow *= glow_color * glow_strength;
    
    COLOR = tex + glow * tex.a;
    COLOR.a = tex.a;
}