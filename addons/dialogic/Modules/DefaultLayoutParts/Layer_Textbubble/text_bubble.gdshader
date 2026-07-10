shader_type canvas_item;

uniform float radius : hint_range(1.0, 200, 0.01) = 25;
uniform vec2 box_size = vec2(100, 100);
uniform float box_padding = 15;
uniform float wobble_amount : hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float wobble_speed : hint_range(0.0, 10.0, 0.01) = 1;
uniform float wobble_detail : hint_range(0.01, 1, 0.01) = 0.5;

void fragment() {
	float adjusted_radius = min(min(radius, box_size.x/2.0), box_size.y/2.0);
	vec2 detail_uv = UV * mix(8.0, 24.0, wobble_detail);
	float phase = TIME * wobble_speed;
	vec2 deformation = vec2(
		sin(detail_uv.y + phase) + sin(detail_uv.x * 1.7 - phase * 0.7),
		cos(detail_uv.x + phase * 0.8) + cos(detail_uv.y * 1.3 - phase)
	) * 0.18;
	vec2 deformed_UV = UV + deformation * (vec2(box_padding) / box_size) * wobble_amount;
	float rounded_box = length(max(abs(deformed_UV*(box_size+vec2(box_padding))-vec2(0.5)*(box_size+vec2(box_padding)))+adjusted_radius-vec2(0.5)*box_size,0))-adjusted_radius;
	COLOR.a = min(smoothstep(0.0, -1, rounded_box), COLOR.a);
}
