shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_position = vec3(0.0, 0.0, 0.0);
uniform float fade_start_height = 1.0;
uniform float fade_end_height = 2.0;

varying vec3 world_vertex;

void vertex() {
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float vertex_height = world_vertex.y - base_position.y;
	float alpha = 1.0 - smoothstep(fade_start_height, fade_end_height, vertex_height);
	ALPHA = alpha;
	ALBEDO=ALBEDO;

	if (alpha <= 0.0) {
		discard;
	}
}
