shader_type spatial;
// 賒帳街的地面（TownScenery）：街中間一排一排錯開的石板，兩邊房子腳下一條排水溝的深色石條，石縫裡長一點苔；
// 東門外面換成土路。位置照世界座標算。

uniform float street_half = 5.0;
uniform float gate_x = 58.0;

varying vec3 world_pos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	vec2 size = vec2(0.36, 0.26);
	float row = floor(p.y / size.y);
	vec2 q = vec2(p.x / size.x + 0.5 * mod(row, 2.0), p.y / size.y);
	vec2 id = floor(q);
	vec2 f = fract(q);
	vec2 e = min(f, 1.0 - f) * size;
	float gap = smoothstep(0.01, 0.04, min(e.x, e.y) + (noise(p * 6.0) - 0.5) * 0.02);
	float tone = hash(id);
	vec3 slab = mix(vec3(0.36, 0.33, 0.31), vec3(0.52, 0.47, 0.41), tone) * (0.82 + 0.26 * noise(p * 2.3 + tone * 9.0));
	slab = mix(slab, slab * vec3(0.9, 0.95, 1.05), step(0.8, hash(id + 3.0)));
	vec3 seam = mix(vec3(0.2, 0.18, 0.16), vec3(0.22, 0.27, 0.16), smoothstep(0.55, 0.9, noise(p * 0.7)));
	vec3 col = mix(seam, slab, gap);
	// 中間被走得比較亮、兩邊靠牆暗
	col *= mix(1.04, 0.82, smoothstep(street_half * 0.4, street_half, abs(p.y)));
	// 排水溝：牆腳一條深色的石條
	float gutter = smoothstep(street_half - 0.55, street_half - 0.45, abs(p.y)) * (1.0 - smoothstep(street_half - 0.05, street_half + 0.05, abs(p.y)));
	col = mix(col, vec3(0.3, 0.29, 0.28) * (0.8 + 0.3 * hash(vec2(floor(p.x / 0.6), 3.0))), gutter);
	// 東門外：土路，兩邊長草
	float outside = smoothstep(gate_x + 1.0, gate_x + 3.0, p.x);
	vec3 dirt = mix(vec3(0.42, 0.33, 0.24), vec3(0.5, 0.41, 0.3), noise(p * 1.7));
	vec3 grass = mix(vec3(0.24, 0.36, 0.18), vec3(0.32, 0.44, 0.2), noise(p * 0.9));
	vec3 road = mix(dirt, grass, smoothstep(2.0, 3.5, abs(p.y) + noise(p * 0.5) * 1.2));
	col = mix(col, road, outside);
	ALBEDO = col;
	ROUGHNESS = 0.92;
	SPECULAR = 0.15;
}
