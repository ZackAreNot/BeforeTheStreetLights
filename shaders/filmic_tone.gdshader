shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength : hint_range(0.0, 1.0, 0.01) = 0.24;
uniform float shadow_lift : hint_range(0.0, 0.12, 0.005) = 0.035;
uniform float curve_strength : hint_range(0.0, 0.5, 0.01) = 0.16;
uniform float highlight_rolloff : hint_range(0.0, 0.5, 0.01) = 0.14;

float luminance(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec3 base_color = texture(screen_texture, SCREEN_UV).rgb;
	float luma = luminance(base_color);
	float shadow_mask = 1.0 - smoothstep(0.08, 0.52, luma);
	vec3 lifted = base_color + (1.0 - base_color) * shadow_lift * shadow_mask;

	vec3 s_curve = lifted * lifted * (3.0 - 2.0 * lifted);
	vec3 shaped = mix(lifted, s_curve, curve_strength);
	vec3 rolled = shaped - max(shaped - vec3(0.72), vec3(0.0)) * highlight_rolloff;
	vec3 result = mix(base_color, rolled, strength);

	COLOR = vec4(clamp(result, 0.0, 1.0), 1.0);
}
