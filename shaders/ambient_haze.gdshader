shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float amount : hint_range(0.0, 0.2, 0.005) = 0.045;
uniform float horizon_height : hint_range(0.1, 0.9, 0.01) = 0.42;
uniform float horizon_spread : hint_range(0.1, 0.7, 0.01) = 0.38;
uniform float shadow_response : hint_range(0.0, 1.0, 0.01) = 0.62;
uniform vec4 haze_color : source_color = vec4(0.88, 0.91, 0.82, 1.0);

float luminance(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 base_color = texture(screen_texture, uv).rgb;
	float horizon = 1.0 - smoothstep(
		0.0,
		horizon_spread,
		abs(uv.y - horizon_height)
	);
	float upper_air = 1.0 - smoothstep(0.0, 0.95, uv.y);
	float depth_mask = clamp(horizon * 0.72 + upper_air * 0.28, 0.0, 1.0);
	float shadow_mask = 1.0 - smoothstep(0.12, 0.62, luminance(base_color));
	float haze_mix = amount * depth_mask * mix(0.55, 1.0, shadow_mask * shadow_response);
	vec3 result = mix(base_color, haze_color.rgb, haze_mix);

	COLOR = vec4(clamp(result, 0.0, 1.0), 1.0);
}
