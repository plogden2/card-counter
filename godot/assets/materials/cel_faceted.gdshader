shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_toon;

uniform vec4 albedo_color : source_color = vec4(0.7, 0.65, 0.6, 1.0);

void fragment() {
	ALBEDO = albedo_color.rgb;
	ROUGHNESS = 0.92;
	SPECULAR = 0.18;
}
