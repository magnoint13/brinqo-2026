shader_type canvas_item;

void vertex() {
}

void fragment() {
	vec2 pos = UV.xy - vec2(0.5f);
	float value = exp(- (pos.x * pos.x + pos.y * pos.y) / (2.0f * 0.25f * 0.25f));
	COLOR = value * value * vec4(1.0f, 1.0f, 0.0f, 1.0f);
}

