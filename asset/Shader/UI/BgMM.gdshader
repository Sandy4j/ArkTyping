shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.6;
uniform float vignette_size : hint_range(0.0, 2.0) = 0.8;
uniform float brightness : hint_range(-1.0, 1.0) = 0.0;
uniform float contrast : hint_range(0.0, 2.0) = 1.1;
uniform float saturation : hint_range(0.0, 2.0) = 1.2;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    tex.rgb += brightness;
    tex.rgb = (tex.rgb - 0.5) * contrast + 0.5;

    float gray = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
    tex.rgb = mix(vec3(gray), tex.rgb, saturation);

    vec2 vignette_uv = UV * 2.0 - 1.0;
    float vignette = 1.0 - length(vignette_uv) * vignette_size;
    vignette = smoothstep(0.0, 1.0, vignette);
    vignette = mix(1.0, vignette, vignette_strength);

    tex.rgb *= vignette;

    COLOR = tex;
}