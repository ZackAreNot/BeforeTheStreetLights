shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 0.35, 0.005) = 0.09;
uniform float threshold : hint_range(0.35, 0.95, 0.01) = 0.62;
uniform float softness : hint_range(0.05, 0.35, 0.01) = 0.18;
uniform float radius : hint_range(1.0, 5.0, 0.1) = 2.8;
uniform vec4 bloom_tint : source_color = vec4(1.0, 0.91, 0.75, 1.0);

float luminance(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 base_color = texture(screen_texture, uv).rgb;
	vec3 blur_near = textureLod(screen_texture, uv, radius).rgb;
	vec3 blur_far = textureLod(screen_texture, uv, radius + 1.25).rgb;
	vec3 soft_color = mix(blur_near, blur_far, 0.42);

	float glow_mask = smoothstep(
		threshold - softness,
		threshold + softness,
		luminance(soft_color)
	);
	vec3 highlight = max(soft_color - vec3(threshold * 0.72), vec3(0.0));
	vec3 glow = highlight * bloom_tint.rgb * glow_mask;
	vec3 result = base_color + glow * intensity;

	COLOR = vec4(clamp(result, 0.0, 1.0), 1.0);
}
