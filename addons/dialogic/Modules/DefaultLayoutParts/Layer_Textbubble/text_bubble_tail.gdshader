shader_type canvas_item;
render_mode unshaded;

uniform float edge_softness : hint_range(0.35, 1.0, 0.05) = 0.5;

void fragment() {
	float half_width = (1.0 - UV.y) * 0.5;
	float distance_to_edge = half_width - abs(UV.x - 0.5);
	float antialias_width = max(fwidth(distance_to_edge) * edge_softness, 0.0002);
	COLOR.a *= smoothstep(-antialias_width, antialias_width, distance_to_edge);
}
