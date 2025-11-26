shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float desaturation : hint_range(0.0, 1.0) = 0.85;
uniform float brightness : hint_range(0.5, 1.5) = 0.9;

void fragment() {
    vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    
    // Convert to grayscale using luminance values
    float luminance = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    
    // Mix between original color and grayscale based on desaturation
    vec3 result = mix(screen_color.rgb, grayscale, desaturation);
    
    // Apply brightness adjustment
    result *= brightness;
    
    COLOR = vec4(result, screen_color.a);
}