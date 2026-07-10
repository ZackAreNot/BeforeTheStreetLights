shader_type canvas_item;

uniform float radius : hint_range(1.0, 200, 0.01) = 25;
uniform vec2 box_size = vec2(100, 100);
uniform float box_padding = 15;
uniform float wobble_amount : hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float wobble_speed : hint_range(0.0, 10.0, 0.01) = 1;
uniform float wobble_detail : hint_range(0.01, 1, 0.01) = 0.5;

void fragment() {
	float adjusted_radius = min(min(radius, box_size.x/2.0), box_size.y/2.0);
	float primary_frequency = mix(1.8, 4.2, wobble_detail);
	float phase = TIME * wobble_speed * 2.6;
	vec2 deformation = vec2(
		sin(UV.y * 6.283185 * primary_frequency + phase)
			+ 0.45 * sin(UV.y * 6.283185 * primary_frequency * 2.37 - phase * 1.31),
		cos(UV.x * 6.283185 * primary_frequency * 0.83 + phase * 0.91)
			+ 0.45 * cos(UV.x * 6.283185 * primary_frequency * 2.11 - phase * 1.17)
	) / 1.45;
	float amplitude_pixels = wobble_amount * 10.0;
	vec2 deformed_UV = UV + deformation * (
		vec2(amplitude_pixels) / max(box_size, vec2(1.0))
	);
	float rounded_box = length(max(abs(deformed_UV*(box_size+vec2(box_padding))-vec2(0.5)*(box_size+vec2(box_padding)))+adjusted_radius-vec2(0.5)*box_size,0))-adjusted_radius;
	COLOR.a = min(smoothstep(0.0, -1, rounded_box), COLOR.a);
}
