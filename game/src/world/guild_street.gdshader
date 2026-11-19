shader_type spatial;
// 公會大門外面的那條街（GuildScenery）：從屋裡往門外看得到的地面（石板路）與街對面的房子（一片面，畫木骨架的房子、窗、門、屋頂、天）。
// 不受光：屋裡暗、外面是白天，外面的東西整片照 `daylight` 的顏色亮（傍晚是橘的）。位置照世界座標算。
// part：0＝石板路（水平的面）、1＝街對面的房子（朝北的一片直的面）。
render_mode unshaded, cull_back, fog_disabled;

uniform int part = 0;
uniform vec3 daylight : source_color = vec3(1.0, 0.97, 0.9);
uniform vec3 sky_top : source_color = vec3(0.55, 0.75, 1.0);
uniform vec3 sky_low : source_color = vec3(0.92, 0.95, 1.0);

varying vec3 world_pos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 cobbles(vec2 p) {
	// 一排一排錯開的石板，每塊深淺不同、縫是暗的
	vec2 size = vec2(0.42, 0.3);
	float row = floor(p.y / size.y);
	vec2 q = vec2(p.x / size.x + 0.5 * mod(row, 2.0), p.y / size.y);
	vec2 id = floor(q);
	vec2 f = fract(q);
	vec2 e = min(f, 1.0 - f) * size;
	float gap = smoothstep(0.012, 0.035, min(e.x, e.y));
	float tone = hash(id);
	vec3 stone = mix(vec3(0.62, 0.58, 0.52), vec3(0.74, 0.7, 0.62), tone) * (0.92 + 0.08 * hash(id + floor(f * 4.0)));
	return mix(vec3(0.3, 0.27, 0.24), stone, gap);
}

vec3 houses(vec2 p) {
	// p.x＝沿著街、p.y＝高。每一棟寬 4～6 m（照位置算出來的），屋簷 5～6.5 m、山形屋頂
	float w = 5.0;
	float id = floor((p.x + 40.0) / w);
	float x = fract((p.x + 40.0) / w) * w;
	float eave = 5.0 + 1.5 * hash(vec2(id, 1.0));
	float peak = 1.4 + 1.2 * hash(vec2(id, 2.0));
	float roof_y = eave + peak * (1.0 - abs(x / w - 0.5) * 2.0);
	vec3 sky = mix(sky_low, sky_top, clamp((p.y - 4.0) / 8.0, 0.0, 1.0));
	if (p.y > roof_y + 0.25) {
		return sky;
	}
	if (p.y > eave) {
		// 屋頂：深紅褐色的瓦，一排一排
		float tile = smoothstep(0.0, 0.06, fract(p.y * 3.0)) * 0.15 + 0.85;
		return vec3(0.42, 0.2, 0.15) * tile * (0.9 + 0.1 * hash(vec2(id, 3.0)));
	}
	vec3 plaster = mix(vec3(0.9, 0.84, 0.72), vec3(0.86, 0.8, 0.82), hash(vec2(id, 4.0)));
	vec3 timber = vec3(0.3, 0.19, 0.12);
	vec3 col = plaster;
	// 木骨架：房子兩邊的柱、每 1.25 m 一根、樓板那一道橫木、屋簷下一道
	float post = min(x, w - x);
	float frame = 1.0 - step(0.12, post);
	frame = max(frame, 1.0 - step(0.06, abs(fract(x / 1.25 + 0.5) - 0.5) * 1.25));
	frame = max(frame, 1.0 - step(0.1, abs(p.y - 2.9)));
	frame = max(frame, 1.0 - step(0.12, abs(p.y - eave + 0.1)));
	// 窗：一樓、二樓各一排（每格 1.25 m 的中間），有的亮著
	float cx = abs(fract(x / 1.25) - 0.5) * 1.25;
	float win1 = step(cx, 0.32) * step(1.1, p.y) * step(p.y, 2.2);
	float win2 = step(cx, 0.32) * step(3.5, p.y) * step(p.y, 4.5);
	float has = step(0.35, hash(vec2(id, floor(x / 1.25) + 7.0)));
	vec3 glass = mix(vec3(0.2, 0.25, 0.35), vec3(0.95, 0.85, 0.6), step(0.8, hash(vec2(id, floor(x / 1.25) + 11.0))));
	col = mix(col, glass, max(win1, win2) * has);
	// 一樓中間一扇門
	float door = step(abs(x - w * 0.5), 0.55) * step(p.y, 2.3);
	col = mix(col, vec3(0.32, 0.2, 0.13), door);
	col = mix(col, timber, frame * (1.0 - door));
	// 最下面一截石頭的基座
	col = mix(col, vec3(0.55, 0.52, 0.48), step(p.y, 0.45));
	return col;
}

void fragment() {
	vec3 col = part == 0 ? cobbles(world_pos.xz) : houses(world_pos.xy);
	ALBEDO = col * daylight;
}
