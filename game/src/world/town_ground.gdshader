shader_type spatial;
// 賒帳街的地面（TownScenery）：街中間一排一排錯開的石板，兩邊房子腳下一條排水溝的深色石條，石縫裡長一點苔；
// 東門外面換成土路；房子後面（到城牆為止）是踩實的土與雜草，藥房後院是土（只有街與通到後院的那條小巷鋪石板）。
// 位置照世界座標算。

uniform float street_half = 5.0;
uniform float gate_x = 58.0;
// 藥房後院（x 最小、z 最小、x 最大、z 最大）、從街上通到後院的小巷（同樣的順序）
uniform vec4 yard = vec4(1.0, 10.6, 14.5, 17.5);
uniform vec4 alley = vec4(10.0, 0.0, 13.6, 10.6);

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
	// 暖灰的石板（以前偏亮：太陽下一片白）
	vec3 slab = mix(vec3(0.3, 0.27, 0.24), vec3(0.45, 0.39, 0.32), tone) * (0.82 + 0.26 * noise(p * 2.3 + tone * 9.0));
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
	// 房子後面：踩實的土，一塊一塊的雜草（小巷照舊是石板）；後院：土，中間被踩得比較淺、邊上顏色深
	float wobble = (noise(p * 1.9) - 0.5) * 0.5;
	float in_alley = step(alley.x, p.x) * step(p.x, alley.z) * step(alley.y, p.y) * step(p.y, alley.w + wobble);
	float back = smoothstep(street_half + 0.5, street_half + 1.1, abs(p.y) + wobble) * (1.0 - in_alley);
	vec3 backlot = mix(dirt * 0.82, grass * 0.9, smoothstep(0.5, 0.75, noise(p * 0.45 + 7.0)));
	float in_yard = step(yard.x, p.x) * step(p.x, yard.z) * step(yard.y + wobble, p.y) * step(p.y, yard.w);
	vec2 yard_mid = vec2((yard.x + yard.z) * 0.5, (yard.y + yard.w) * 0.5);
	vec3 yard_dirt = dirt * mix(1.0, 0.8, smoothstep(1.5, 4.5, length((p - yard_mid) * vec2(0.6, 1.0)) + noise(p * 0.8) * 1.5));
	backlot = mix(backlot, yard_dirt, in_yard);
	col = mix(col, backlot, back);
	col = mix(col, road, outside);
	ALBEDO = col;
	ROUGHNESS = 0.92;
	SPECULAR = 0.15;
}
