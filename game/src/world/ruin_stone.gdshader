shader_type spatial;
// 廢棄祭壇的石頭（祭壇本體與周圍的斷柱）。Tripo 那個祭壇模型的顏色貼圖是一張灰的（預覽圖有顏色、貼圖沒有），
// 所以顏色照形狀算：一塊一塊深淺不同的藍灰石頭、朝上的面與靠近地面的地方長苔、側面一圈會亮的符文（四面各一塊，
// 每塊是幾格亮幾格暗的方塊字）、頂面刻一圈圓環。原本的灰貼圖只當表面的明暗細節，法線貼圖照用。
// 位置用「離底部中心多遠」算（base_pos、size：關卡給），同一個 shader 給祭壇與每一根柱子用。
// glow：符文多亮（魔像醒著的時候關卡會讓它一下一下跳）；rune_color：平常是病綠色。

uniform sampler2D detail : filter_linear_mipmap, repeat_enable, hint_default_white;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec3 base_pos = vec3(0.0);
// 高度、半徑（公尺）：符文的那一圈照這兩個數字擺
uniform float height = 1.4;
uniform float radius = 0.9;
uniform float glow = 1.0;
uniform vec3 rune_color : source_color = vec3(0.35, 1.0, 0.55);
// 頂面要不要刻圓環（祭壇有，柱子沒有）
uniform float top_ring = 1.0;

varying vec3 world_pos;
varying vec3 world_n;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(world_n);
	vec3 l = world_pos - base_pos;
	float h = l.y / height;
	float r = length(l.xz) / radius;
	float turn = atan(l.z, l.x) / 6.2832 + 0.5;
	// 石塊：繞一圈十塊、上下五層，每塊深淺不同
	float tone = hash(vec2(floor(turn * 10.0 + floor(h * 5.0) * 0.5), floor(h * 5.0)));
	vec3 col = mix(vec3(0.27, 0.28, 0.36), vec3(0.44, 0.44, 0.52), tone);
	// 苔：朝上的面一塊一塊、貼地的一圈
	float patches = noise(l.xz * 3.1 + 17.0) * 0.6 + noise(l.xz * 8.3) * 0.4;
	float mossy = smoothstep(0.35, 0.8, n.y) * smoothstep(0.38, 0.58, patches);
	mossy = max(mossy, (1.0 - smoothstep(0.02, 0.22, h)) * smoothstep(0.3, 0.6, noise(vec2(turn * 40.0, h * 9.0))));
	col = mix(col, vec3(0.17, 0.32, 0.15), clamp(mossy, 0.0, 1.0) * 0.85);
	// 側面的符文：四面各一塊，三欄五列的格子，亮的格子連成方塊字
	float side = 1.0 - smoothstep(0.3, 0.6, abs(n.y));
	float u = fract(turn * 4.0);
	float v = (h - 0.2) / 0.46;
	vec2 grid = vec2((u - 0.3) / 0.4 * 3.0, v * 5.0);
	float in_panel = step(0.0, grid.x) * step(grid.x, 3.0) * step(0.0, grid.y) * step(grid.y, 5.0);
	vec2 cell = floor(grid);
	vec2 in_cell = fract(grid);
	float lit = step(0.42, hash(cell + vec2(floor(turn * 4.0) * 7.0 + 3.0, 11.0)));
	// 亮的格子上下相連（留左右的縫）：看起來是直的筆畫，不是一顆一顆的點
	float stroke = step(0.2, in_cell.x) * step(in_cell.x, 0.8);
	float rune = side * in_panel * lit * stroke;
	// 頂面：兩圈圓環＋八道放射的刻痕
	float top = smoothstep(0.7, 0.9, n.y) * smoothstep(0.75, 0.9, h) * top_ring;
	float ring = max(1.0 - smoothstep(0.0, 0.045, abs(r - 0.62)), 1.0 - smoothstep(0.0, 0.04, abs(r - 0.34)));
	float spoke = (1.0 - smoothstep(0.0, 0.03, abs(fract(turn * 8.0) - 0.5) * r)) * step(0.34, r) * step(r, 0.62);
	float carve = top * max(ring, spoke);
	float lines = clamp(max(rune, carve), 0.0, 1.0) * (1.0 - clamp(mossy, 0.0, 1.0) * 0.7);
	ALBEDO = mix(col * mix(0.8, 1.1, texture(detail, UV).r), rune_color * 0.35, lines);
	ROUGHNESS = 0.85;
	NORMAL_MAP = texture(normal_map, UV).rgb;
	EMISSION = rune_color * lines * 2.4 * glow;
}
