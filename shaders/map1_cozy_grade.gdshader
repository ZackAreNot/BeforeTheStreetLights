shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float effect_strength : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float exposure : hint_range(-0.25, 0.25, 0.01) = 0.03;
uniform float contrast : hint_range(0.8, 1.3, 0.01) = 1.06;
uniform float saturation : hint_range(0.7, 1.4, 0.01) = 1.08;
uniform float warmth : hint_range(0.0, 1.0, 0.01) = 0.38;
uniform float cool_shadows : hint_range(0.0, 1.0, 0.01) = 0.18;
uniform float golden_glow : hint_range(0.0, 0.35, 0.01) = 0.10;
uniform float vignette_strength : hint_range(0.0, 0.5, 0.01) = 0.14;

float luminance(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 base_color = texture(screen_texture, uv).rgb;
	vec3 color = base_color;

	color *= exp2(exposure);
	color = (color - 0.5) * contrast + 0.5;

	float base_luma = luminance(color);
	color = mix(vec3(base_luma), color, saturation);

	float shadow_mask = 1.0 - smoothstep(0.12, 0.58, base_luma);
	color += vec3(-0.018, 0.008, 0.028) * shadow_mask * cool_shadows;

	float highlight_mask = smoothstep(0.42, 0.92, base_luma);
	color += vec3(0.075, 0.028, -0.035) * warmth * (0.35 + highlight_mask * 0.65);

	vec3 soft_color = textureLod(screen_texture, uv, 3.0).rgb;
	float glow_mask = smoothstep(0.58, 0.95, luminance(soft_color));
	color += soft_color * glow_mask * golden_glow;

	vec2 centered_uv = uv * 2.0 - 1.0;
	float edge_distance = dot(centered_uv, centered_uv * vec2(0.58, 1.0));
	float vignette = smoothstep(0.48, 1.45, edge_distance);
	color *= 1.0 - vignette * vignette_strength;

	vec3 graded_color = clamp(color, 0.0, 1.0);
	COLOR = vec4(mix(base_color, graded_color, effect_strength), 1.0);
}
