shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength : hint_range(0.0, 0.5, 0.01) = 0.14;
uniform float inner_radius : hint_range(0.15, 0.9, 0.01) = 0.48;
uniform float outer_radius : hint_range(0.5, 1.5, 0.01) = 1.16;
uniform float center_lift : hint_range(0.0, 0.08, 0.005) = 0.015;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 base_color = texture(screen_texture, uv).rgb;
	vec2 centered = (uv - vec2(0.5)) * vec2(0.82, 1.0);
	float radius = length(centered) * 2.0;
	float edge = smoothstep(inner_radius, outer_radius, radius);
	float center = 1.0 - smoothstep(0.0, inner_radius, radius);
	vec3 result = base_color * (1.0 - edge * strength);
	result += base_color * center * center_lift;

	COLOR = vec4(clamp(result, 0.0, 1.0), 1.0);
}
