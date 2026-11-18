shader_type spatial;

uniform vec3 blue : source_color = vec3(0.0, 0.0, 1.0);
uniform vec3 red : source_color = vec3(1.0, 0.0, 0.0);
uniform float preview_alpha : hint_range(0.0, 1.0) = 0.5;

void vertex() {
	COLOR.r = VERTEX.y;
}

void fragment() {
	float t = clamp(COLOR.r + 0.5, 0.0, 1.0);
	ALBEDO = mix(blue, red, t);
	ALPHA = preview_alpha;
}
