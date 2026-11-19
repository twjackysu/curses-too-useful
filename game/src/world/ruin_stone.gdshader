shader_type spatial;
// 廢棄祭壇的石頭（祭壇本體與周圍的斷柱）。Tripo 那個祭壇模型的顏色貼圖是一張灰的（預覽圖有顏色、貼圖沒有），
// 所以顏色照形狀算：一塊一塊深淺不同的藍灰石頭、朝上的面與靠近地面的地方長苔、側面一圈會亮的符文（四面各一塊，
// 每塊上下三個字，每個字是一根直的筆畫加幾道斜的、橫的、一個圈——D-306 以前是幾格亮幾格暗的方塊）、頂面刻一圈圓環。
// 原本的灰貼圖只當表面的明暗細節，法線貼圖照用。
// flutes > 0（斷柱）：側面一圈凹槽（照角度把法線往兩邊推，看起來是一道一道的直溝）、一節一節（course 公尺一節）的深淺不同、
// 節與節的接縫暗一點，不再是「繞一圈十塊」的直條（看起來一面一面的）。
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
// 斷柱：一圈幾道凹槽（0＝沒有：祭壇、台階）、一節多高
uniform float flutes = 0.0;
uniform float course = 1.15;

varying vec3 world_pos;
varying vec3 world_n;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x), u.y);
}

// 點 p 到線段 a–b 的距離
float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}

// 一個符文字（q＝字裡的位置 0～1、id＝哪一個字）：一根直的筆畫，加上照 id 挑的幾道斜的、橫的、一個圈。回傳離筆畫多遠
float glyph(vec2 q, float id) {
	float d = seg(q, vec2(0.5, 0.08), vec2(0.5, 0.92));
	float big = 9.0;
	d = min(d, hash(vec2(id, 1.0)) < 0.5 ? seg(q, vec2(0.5, 0.78), vec2(0.18, 0.52)) : big);
	d = min(d, hash(vec2(id, 2.0)) < 0.5 ? seg(q, vec2(0.5, 0.78), vec2(0.82, 0.52)) : big);
	d = min(d, hash(vec2(id, 3.0)) < 0.4 ? seg(q, vec2(0.5, 0.42), vec2(0.18, 0.16)) : big);
	d = min(d, hash(vec2(id, 4.0)) < 0.4 ? seg(q, vec2(0.5, 0.42), vec2(0.82, 0.16)) : big);
	d = min(d, hash(vec2(id, 5.0)) < 0.3 ? seg(q, vec2(0.22, 0.92), vec2(0.78, 0.92)) : big);
	d = min(d, hash(vec2(id, 6.0)) < 0.35 ? seg(q, vec2(0.5, 0.6), vec2(0.8, 0.78)) : big);
	d = min(d, hash(vec2(id, 7.0)) < 0.25 ? abs(length(q - vec2(0.5, 0.5)) - 0.2) : big);
	return d;
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
	// 石塊：繞一圈十塊、上下五層，每塊深淺不同（祭壇、台階）；斷柱是一節一節的，每節深淺不同、表面一塊一塊斑駁
	float tone = hash(vec2(floor(turn * 10.0 + floor(h * 5.0) * 0.5), floor(h * 5.0)));
	float side_n = 1.0 - smoothstep(0.3, 0.6, abs(n.y));
	float fluted = step(0.5, flutes) * side_n * (1.0 - smoothstep(0.06, 0.16, abs(r - 1.0)));
	float joint = 0.0;
	if (flutes > 0.5) {
		float drum = floor(l.y / course);
		tone = hash(vec2(drum, 7.3)) * 0.55 + noise(vec2(turn * 9.0, l.y * 2.2) + drum * 3.1) * 0.45;
		// 節與節的接縫：一道細細的暗線
		joint = (1.0 - smoothstep(0.0, 0.035, abs(fract(l.y / course + 0.5) - 0.5) * course)) * side_n * step(0.2, l.y);
	}
	vec3 col = mix(vec3(0.27, 0.28, 0.36), vec3(0.44, 0.44, 0.52), tone);
	col *= 1.0 - joint * 0.55;
	// 苔：朝上的面一塊一塊、貼地的一圈
	float patches = noise(l.xz * 3.1 + 17.0) * 0.6 + noise(l.xz * 8.3) * 0.4;
	float mossy = smoothstep(0.35, 0.8, n.y) * smoothstep(0.38, 0.58, patches);
	mossy = max(mossy, (1.0 - smoothstep(0.02, 0.22, h)) * smoothstep(0.3, 0.6, noise(vec2(turn * 40.0, h * 9.0))));
	col = mix(col, vec3(0.17, 0.32, 0.15), clamp(mossy, 0.0, 1.0) * 0.85);
	// 側面的符文：四面各一塊，上下三個字（每個字是筆畫，不是方塊）；筆畫的邊用 fwidth 抗鋸齒
	float side = side_n;
	float u = fract(turn * 4.0);
	float v = (h - 0.2) / 0.46;
	vec2 panel = vec2((u - 0.34) / 0.32, v * 3.0);
	float in_panel = step(0.0, panel.x) * step(panel.x, 1.0) * step(0.0, panel.y) * step(panel.y, 3.0);
	vec2 q = vec2(panel.x, fract(panel.y));
	float id = floor(turn * 4.0) * 3.0 + floor(panel.y) + floor(base_pos.x * 7.0 + base_pos.z * 3.0);
	float dist = glyph(q, id);
	float aa = max(fwidth(dist), 0.01);
	float rune = side * in_panel * (1.0 - smoothstep(0.075 - aa, 0.075 + aa, dist));
	// 頂面：兩圈圓環＋八道放射的刻痕
	float top = smoothstep(0.7, 0.9, n.y) * smoothstep(0.75, 0.9, h) * top_ring;
	float ring = max(1.0 - smoothstep(0.0, 0.045, abs(r - 0.62)), 1.0 - smoothstep(0.0, 0.04, abs(r - 0.34)));
	float spoke = (1.0 - smoothstep(0.0, 0.03, abs(fract(turn * 8.0) - 0.5) * r)) * step(0.34, r) * step(r, 0.62);
	float carve = top * max(ring, spoke);
	float lines = clamp(max(rune, carve), 0.0, 1.0) * (1.0 - clamp(mossy, 0.0, 1.0) * 0.7);
	ALBEDO = mix(col * mix(0.8, 1.1, texture(detail, UV).r), rune_color * 0.35, lines);
	ROUGHNESS = 0.85;
	NORMAL_MAP = texture(normal_map, UV).rgb;
	if (fluted > 0.0) {
		// 凹槽：沿著圓周的方向把法線往兩邊推（一道一道的直溝），接縫附近不推（每一節的上下緣是平的）
		vec3 tangent = normalize(vec3(-l.z, 0.0, l.x));
		float wave = sin(turn * 6.2832 * flutes);
		vec3 bent = normalize(n + tangent * wave * 0.45 * fluted * (1.0 - joint));
		NORMAL = normalize((VIEW_MATRIX * vec4(bent, 0.0)).xyz);
		col *= 1.0 - 0.12 * fluted * (1.0 - abs(wave));
		ALBEDO = mix(col * mix(0.8, 1.1, texture(detail, UV).r), rune_color * 0.35, lines);
	}
	EMISSION = rune_color * lines * 2.4 * glow;
}
