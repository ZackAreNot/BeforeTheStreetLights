shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float amount : hint_range(0.0, 0.04, 0.001) = 0.008;
uniform float grain_size : hint_range(1.0, 4.0, 0.25) = 1.5;
uniform float motion_speed : hint_range(0.0, 8.0, 0.1) = 1.8;

float hash_noise(vec2 coordinate) {
	return fract(sin(dot(coordinate, vec2(12.9898, 78.233))) * 43758.5453);
}

float luminance(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec3 base_color = texture(screen_texture, SCREEN_UV).rgb;
	vec2 grain_coordinate = floor(FRAGCOORD.xy / grain_size);
	grain_coordinate += vec2(TIME * motion_speed, -TIME * motion_speed * 0.73);
	float noise = hash_noise(grain_coordinate) * 2.0 - 1.0;
	float luma = luminance(base_color);
	float midtone_mask = 0.45 + 0.55 * (1.0 - abs(luma * 2.0 - 1.0));
	vec3 result = base_color + vec3(noise * amount * midtone_mask);

	COLOR = vec4(clamp(result, 0.0, 1.0), 1.0);
}
