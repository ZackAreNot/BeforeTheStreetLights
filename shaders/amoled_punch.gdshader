shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength : hint_range(0.0, 1.0, 0.01) = 0.52;
uniform float black_point : hint_range(0.0, 0.2, 0.005) = 0.055;
uniform float saturation_boost : hint_range(0.0, 0.6, 0.01) = 0.26;
uniform float contrast_boost : hint_range(0.0, 0.4, 0.01) = 0.13;
uniform float highlight_protection : hint_range(0.0, 1.0, 0.01) = 0.82;

float luminance(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec3 base_color = texture(screen_texture, SCREEN_UV).rgb;
	float base_luma = luminance(base_color);
	vec3 deep_color = max(
		(base_color - vec3(black_point)) / max(1.0 - black_point, 0.001),
		vec3(0.0)
	);
	float deep_luma = luminance(deep_color);
	deep_color = mix(vec3(deep_luma), deep_color, 1.0 + saturation_boost);
	deep_color = (deep_color - 0.5) * (1.0 + contrast_boost) + 0.5;

	float highlight_mask = smoothstep(0.64, 0.98, base_luma) * highlight_protection;
	deep_color = mix(deep_color, base_color, highlight_mask);
	vec3 result = mix(base_color, clamp(deep_color, 0.0, 1.0), strength);

	COLOR = vec4(result, 1.0);
}
