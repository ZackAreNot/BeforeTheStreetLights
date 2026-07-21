shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength : hint_range(0.0, 3.0, 0.05) = 0.7;
uniform float speed : hint_range(0.0, 2.0, 0.01) = 0.32;
uniform float wave_scale : hint_range(2.0, 18.0, 0.1) = 7.5;
uniform float lower_fade_start : hint_range(0.25, 0.9, 0.01) = 0.5;
uniform float lower_fade_end : hint_range(0.35, 1.0, 0.01) = 0.92;

void fragment() {
	vec2 uv = SCREEN_UV;
	float time = TIME * speed;
	float broad_wave = sin(uv.y * wave_scale * 6.283185 + time * 2.1);
	float fine_wave = sin(
		uv.y * wave_scale * 11.7 + uv.x * 5.2 - time * 3.4
	) * 0.42;
	float slow_gust = sin(time * 0.83 + uv.y * 4.6) * 0.5 + 0.5;
	float air_mask = 1.0 - smoothstep(lower_fade_start, lower_fade_end, uv.y);
	float horizontal_motion = (broad_wave + fine_wave) * mix(0.45, 1.0, slow_gust);
	float vertical_motion = sin(uv.x * 9.0 + time * 1.7) * 0.18;
	vec2 offset = vec2(horizontal_motion, vertical_motion) * SCREEN_PIXEL_SIZE;
	offset *= strength * air_mask;
	vec2 sample_uv = clamp(uv + offset, SCREEN_PIXEL_SIZE, vec2(1.0) - SCREEN_PIXEL_SIZE);
	vec3 result = texture(screen_texture, sample_uv).rgb;

	COLOR = vec4(result, 1.0);
}
