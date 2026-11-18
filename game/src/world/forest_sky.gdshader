shader_type sky;
// 腐敗之森的夜空（ForestScenery.build_environment；祭壇那一關共用）：頭頂暗紫、地平線泛紫，
// 上半片灑星星（一格最多一顆，大小、亮度照格子的亂數；不眨：用到 TIME 的天空每一幀都要重畫），一輪偏青白的月亮＋一圈光暈。全部用算的，沒有貼圖。
// 月亮擺在玩家往北走時看得到的地方（moon_dir），不跟月光的方向一致——月光從玩家背後照過來，照實擺會在鏡頭後面。

uniform vec3 top_color : source_color = vec3(0.05, 0.03, 0.1);
uniform vec3 horizon_color : source_color = vec3(0.3, 0.19, 0.4);
uniform vec3 ground_color : source_color = vec3(0.07, 0.05, 0.11);
uniform float curve = 0.25;
uniform vec3 moon_dir = vec3(0.35, 0.42, -0.84);
uniform vec3 moon_color : source_color = vec3(0.86, 0.9, 1.0);
uniform float moon_size = 0.045;
uniform float moon_glow = 0.4;
uniform float star_density = 0.11;
uniform float star_energy = 2.2;

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }

// 方向切成格子：每一格最多一顆星，位置在格子裡亂數擺
float stars(vec3 d, float cells) {
	vec3 p = d * cells;
	vec3 cell = floor(p);
	vec3 local = fract(p) - 0.5;
	float pick = hash(cell);
	if (pick > star_density) {
		return 0.0;
	}
	vec3 offset = (vec3(hash(cell + 1.7), hash(cell + 9.2), hash(cell + 4.4)) - 0.5) * 0.6;
	float r = length(local - offset);
	float size = mix(0.1, 0.26, hash(cell + 3.3));
	return (1.0 - smoothstep(size * 0.3, size, r)) * mix(0.4, 1.0, hash(cell + 7.7));
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float up = clamp(d.y, 0.0, 1.0);
	vec3 col = mix(horizon_color, top_color, pow(up, curve));
	if (d.y < 0.0) {
		col = mix(horizon_color, ground_color, clamp(-d.y * 6.0, 0.0, 1.0));
	}
	// 星星：靠地平線那一截淡掉（那裡是霧與樹梢）
	float star_fade = smoothstep(0.08, 0.35, d.y);
	float s = stars(d, 90.0) + stars(d, 170.0) * 0.6;
	col += vec3(0.85, 0.82, 1.0) * s * star_fade * star_energy;
	// 月亮：一片圓（邊緣有一點柔），表面幾塊比較暗的斑，外面一圈慢慢淡掉的光暈
	vec3 m = normalize(moon_dir);
	float a = acos(clamp(dot(d, m), -1.0, 1.0));
	float disc = 1.0 - smoothstep(moon_size * 0.92, moon_size, a);
	vec3 side = normalize(cross(m, vec3(0.0, 1.0, 0.0)));
	vec3 upv = cross(side, m);
	vec2 uv = vec2(dot(d, side), dot(d, upv)) / moon_size;
	float maria = smoothstep(0.35, 0.0, length(uv - vec2(-0.25, 0.2))) * 0.18 + smoothstep(0.3, 0.0, length(uv - vec2(0.3, -0.15))) * 0.14;
	col = mix(col, moon_color * (1.25 - maria), disc);
	col += moon_color * moon_glow * exp(-a / (moon_size * 1.6)) * (1.0 - disc);
	COLOR = col;
}
