shader_type spatial;
// 廢棄祭壇那一塊空地的地面：外圍跟腐敗之森同一套暗土、苔與腐葉（顏色跟 forest_ground.gdshader 一樣，兩關接得起來），
// 中間是一圈一圈鋪的石板（每塊深淺不同、縫裡長苔、有幾塊碎了露出土），南邊一條土路接進來。全部用算的，沒有貼圖。
// plague：魔像醒著的時候石板的縫透出病綠色的光（關卡每幀寫，一下一下跳）。

uniform vec3 soil : source_color = vec3(0.15, 0.12, 0.18);
uniform vec3 moss : source_color = vec3(0.12, 0.22, 0.18);
uniform vec3 rot : source_color = vec3(0.25, 0.15, 0.31);
uniform vec3 dirt : source_color = vec3(0.37, 0.3, 0.3);
uniform vec3 slab : source_color = vec3(0.33, 0.33, 0.41);
uniform vec3 plague_color : source_color = vec3(0.35, 1.0, 0.45);
// 樹腳下長苔（ForestScenery.moss_mask 畫的那一張）
uniform sampler2D moss_mask : hint_default_black, filter_linear, repeat_disable;
uniform float ground_size = 120.0;
uniform float plaza_radius = 16.0;
uniform float path_half = 2.6;
uniform float ring_width = 1.7;
uniform float plague = 0.0;

varying vec3 world_pos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float patches = fbm(p * 0.16);
	float grain = fbm(p * 1.3 + 31.0);
	float near_tree = texture(moss_mask, p / ground_size + 0.5).r;
	float mossy = max(smoothstep(0.36, 0.48, patches), smoothstep(0.3, 0.55, near_tree + (patches - 0.45) * 0.8));
	vec3 col = mix(soil, moss, mossy);
	col = mix(col, rot, smoothstep(0.58, 0.7, fbm(p * 0.1 + 43.0)) * 0.7 * (1.0 - near_tree));
	float wobble = fbm(p * 0.3 + 7.0) - 0.5;
	float dist = length(p);
	// 南邊的土路（+z 是南）：邊緣跟著雜訊走
	float on_path = (1.0 - smoothstep(path_half - 0.5, path_half + 0.9, abs(p.x) + wobble * 1.6)) * step(0.0, p.y);
	col = mix(col, dirt, on_path * (0.75 + 0.25 * grain));
	col *= 0.78 + 0.44 * grain;
	// 石板：一圈一圈，每圈切成差不多大的幾塊（越外圈越多塊，每圈錯開）
	float in_plaza = 1.0 - smoothstep(plaza_radius - 0.7, plaza_radius + 0.9, dist + wobble * 2.4);
	float ring_i = floor(dist / ring_width);
	float count = 5.0 + ring_i * 5.0;
	float around = (atan(p.y, p.x) / 6.2832 + 0.5 + hash(vec2(ring_i, 3.0))) * count;
	float seg_i = floor(around);
	float to_ring = min(fract(dist / ring_width), 1.0 - fract(dist / ring_width)) * ring_width;
	float to_seg = min(fract(around), 1.0 - fract(around)) * 6.2832 * max(dist, 0.5) / count;
	float joint = 1.0 - smoothstep(0.035, 0.1, min(to_ring, to_seg));
	float id = hash(vec2(ring_i * 13.0 + 1.0, seg_i));
	// 碎掉的那幾塊（越靠外圈越多）露出下面的土與苔
	float broken = step(mix(0.93, 0.7, smoothstep(0.55, 1.0, dist / plaza_radius)), hash(vec2(seg_i + 5.0, ring_i * 7.0)));
	vec3 stone = slab * mix(0.72, 1.12, id) * (0.82 + 0.36 * grain);
	stone = mix(stone, moss * 1.25, smoothstep(0.5, 0.66, fbm(p * 0.55 + 12.0)) * 0.6);
	stone = mix(stone, moss * 0.7, joint * 0.85);
	float paved = in_plaza * (1.0 - broken);
	col = mix(col, stone, paved);
	ALBEDO = col;
	ROUGHNESS = mix(1.0, 0.8, paved);
	EMISSION = plague_color * joint * paved * plague * 0.09;
}
