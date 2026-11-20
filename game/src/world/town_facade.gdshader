shader_type spatial;
// 賒帳街的房子（TownScenery）：一個盒子的四面牆。米色／粉色的灰泥、深色的木骨架（四個角的柱、樓板那一道橫木、屋簷下一道、
// 每 bay 公尺一根細柱）、一樓一截石頭牆腳；二樓一排窗（木框、兩片窗板、有的亮著），面向街的那一面一樓也有窗。
// 窗與木骨架都是畫上去的（不另外做模型）。位置照這棟房子自己的座標算（盒子的 UV 不好用）：box_half＝盒子的半寬與半深。

uniform vec3 box_half = vec3(4.0, 3.0, 3.0);
uniform float floor_y = 2.9;
uniform float bay = 1.6;
uniform vec3 plaster : source_color = vec3(0.92, 0.85, 0.72);
uniform vec3 timber : source_color = vec3(0.32, 0.2, 0.13);
uniform vec3 stone : source_color = vec3(0.55, 0.52, 0.5);
uniform vec3 shutter : source_color = vec3(0.32, 0.5, 0.42);
// 面向街的那一面（本地座標的 +Z）一樓也畫窗；0＝不畫（門口另外擺東西的店）
uniform float ground_windows = 1.0;
uniform float seed = 0.0;
// 傍晚（回程的街）：亮著的窗變多（二樓六成、一樓面向街的四成），亮的玻璃自己發光；白天 0＝照舊（少數幾扇暖黃、不發光）
uniform float dusk = 0.0;
// 亮著的窗發多亮、什麼顏色（暖橘；太亮會連窗櫺一起被打成一片白）
uniform float window_glow = 0.85;
uniform vec3 window_light : source_color = vec3(1.0, 0.58, 0.22);

varying vec3 local_pos;
varying vec3 local_n;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x), u.y);
}

void vertex() {
	local_pos = VERTEX;
	local_n = NORMAL;
}

// 一扇窗：c＝窗的中心（沿牆、高），回傳 (是不是窗的範圍, 顏色)；glow＝這一點是不是亮著的玻璃（0～1，窗櫺與窗框是 0）
vec4 window(vec2 p, vec2 c, float lit, out float glow) {
	glow = 0.0;
	vec2 d = abs(p - c);
	vec2 size = vec2(0.42, 0.55);
	if (d.x > size.x + 0.42 || d.y > size.y + 0.1) {
		return vec4(0.0);
	}
	// 兩邊打開的窗板
	if (d.x > size.x + 0.04) {
		float slat = 0.85 + 0.15 * step(0.5, fract(p.y * 9.0));
		return vec4(1.0, shutter * slat * (d.x > size.x + 0.38 ? 0.6 : 1.0));
	}
	if (d.y > size.y || d.x > size.x) {
		return vec4(1.0, timber * 0.85);
	}
	// 玻璃：暗的藍灰、十字的窗櫺；亮著的是暖黃
	// 傍晚亮著的玻璃自己發光：底色壓暗一點，不然被夕陽照到的那幾扇是白的
	vec3 glass = mix(vec3(0.16, 0.2, 0.27), mix(vec3(1.0, 0.78, 0.42), vec3(0.62, 0.4, 0.2), dusk), lit);
	glass *= 0.85 + 0.3 * smoothstep(-size.y, size.y, p.y - c.y + (p.x - c.x) * 0.6);
	float bar = 1.0 - step(0.035, min(abs(p.x - c.x), abs(p.y - c.y + 0.08)));
	// 亮著的窗：下半截比較亮（屋裡的燈在下面）、每一扇深淺差一點
	glow = lit * (1.0 - bar) * (0.75 + 0.25 * smoothstep(size.y, -size.y, p.y - c.y));
	return vec4(1.0, mix(glass, timber * 0.7, bar));
}

void fragment() {
	vec3 n = local_n;
	// s＝沿著這面牆、y＝高（從地面算）
	float s = abs(n.x) > 0.5 ? local_pos.z * sign(n.x) : -local_pos.x * sign(n.z);
	float wall_half = abs(n.x) > 0.5 ? box_half.z : box_half.x;
	float y = local_pos.y + box_half.y;
	vec3 col = plaster * (0.88 + 0.16 * noise(vec2(s, y) * 1.3 + seed) + 0.05 * noise(vec2(s, y) * 11.0));
	// 屋簷下被遮住的那一段暗一點、牆腳濺到泥
	col *= mix(1.0, 0.78, smoothstep(box_half.y * 2.0 - 0.9, box_half.y * 2.0, y));
	col *= mix(0.82, 1.0, smoothstep(0.5, 1.4, y));
	// 窗：二樓每一格的中間一扇；一樓只畫在面向街的那一面
	float cell = floor(s / bay + 0.5);
	vec2 c2 = vec2(cell * bay, floor_y + 1.25);
	float edge = wall_half - abs(cell * bay);
	vec4 w = vec4(0.0);
	float glow = 0.0;
	if (edge > 0.9 && y > floor_y + 0.3) {
		w = window(vec2(s, y), c2, step(mix(0.72, 0.4, dusk), hash(vec2(cell, seed + 7.0))), glow);
	}
	if (w.x < 0.5 && n.z > 0.5 && ground_windows > 0.5 && edge > 0.9 && y < floor_y - 0.2) {
		w = window(vec2(s, y), vec2(cell * bay, 1.55), dusk * step(0.6, hash(vec2(cell, seed + 10.0))), glow);
	}
	if (w.x > 0.5) {
		col = w.yzw;
	}
	// 木骨架：兩邊的角柱、每一格之間的細柱（窗旁邊）、樓板與屋簷下的橫木、一樓的斜撐
	float post_edge = wall_half - abs(s);
	float frame = 1.0 - smoothstep(0.17, 0.19, post_edge);
	float mid = abs(fract(s / bay) - 0.5) * bay;
	frame = max(frame, (1.0 - smoothstep(0.07, 0.085, mid)) * step(floor_y, y) * (1.0 - w.x));
	frame = max(frame, 1.0 - smoothstep(0.1, 0.12, abs(y - floor_y)));
	frame = max(frame, smoothstep(box_half.y * 2.0 - 0.24, box_half.y * 2.0 - 0.22, y));
	float brace = abs((y - floor_y) + abs(fract(s / (bay * 2.0)) - 0.5) * 2.0 * 1.1);
	frame = max(frame, (1.0 - smoothstep(0.06, 0.08, brace)) * step(floor_y, y) * step(y, floor_y + 1.1) * (1.0 - w.x));
	float fibre = noise(vec2(s * 1.5, y * 14.0));
	col = mix(col, timber * (0.8 + 0.35 * fibre), frame);
	// 牆腳：一截石頭（一塊一塊錯開）
	if (y < 0.55) {
		vec2 q = vec2(s / 0.5 + 0.5 * floor(y / 0.27), y / 0.27);
		vec2 f = fract(q);
		float gap = smoothstep(0.03, 0.09, min(min(f.x, 1.0 - f.x) * 0.5, min(f.y, 1.0 - f.y) * 0.27));
		col = mix(stone * 0.45, stone * (0.8 + 0.3 * hash(floor(q) + seed)), gap);
	}
	ALBEDO = col;
	EMISSION = window_light * glow * dusk * window_glow * (0.75 + 0.5 * hash(vec2(cell, seed)));
	ROUGHNESS = 0.9;
	SPECULAR = 0.12;
}
