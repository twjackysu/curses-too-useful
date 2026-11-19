shader_type canvas_item;
// 標題背景：腐敗之森的夜。月亮、星星、遠近三層樹的剪影、樹之間流動的紫色瘴氣、地上幾朵夜光毒蕈，
// 還有從瘴氣裡往上飄的光點——在下面是紫的，飄上去翻成金色（這個遊戲的「詛咒反轉成增益」）。
// 全部程序生成，不用貼圖。標題字在左邊：左半邊壓暗一點。

uniform vec3 sky_top : source_color = vec3(0.012, 0.012, 0.035);
uniform vec3 sky_low : source_color = vec3(0.11, 0.06, 0.17);
uniform vec3 moon_color : source_color = vec3(0.9, 0.93, 0.8);
uniform vec2 moon_pos = vec2(0.77, 0.2);
uniform vec3 far_color : source_color = vec3(0.075, 0.05, 0.11);
uniform vec3 mid_color : source_color = vec3(0.03, 0.022, 0.05);
uniform vec3 near_color : source_color = vec3(0.008, 0.008, 0.016);
uniform vec3 miasma_color : source_color = vec3(0.55, 0.22, 0.62);
uniform vec3 mushroom_color : source_color = vec3(0.35, 0.95, 0.85);
uniform vec3 curse_color : source_color = vec3(0.75, 0.3, 0.9);
uniform vec3 gold_color : source_color = vec3(1.0, 0.78, 0.32);
uniform float fog_speed = 0.02;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

// 一層樹：每格一棵，樹幹＋兩三團樹冠（圓），有的是枯掉的尖枝。回傳 0～1 的遮罩。
// x 已經乘過畫面比例；ground＝這一層的地面（uv.y），size＝樹多大。
float tree_layer(float x, float y, float cell, float ground, float size, float seed) {
	float m = 0.0;
	float c0 = floor(x / cell);
	for (int k = -1; k <= 1; k++) {
		float c = c0 + float(k);
		float h1 = hash(vec2(c, seed));
		float h2 = hash(vec2(c, seed + 3.7));
		float h3 = hash(vec2(c, seed + 9.1));
		float cx = (c + 0.25 + h1 * 0.5) * cell;
		float base = ground + (h2 - 0.5) * size * 0.12;
		float height = size * (0.55 + h2 * 0.8);
		float top = base - height;
		// 樹幹：往下變粗、微微歪
		float lean = (h3 - 0.5) * 0.25;
		float ty = clamp((y - top) / height, 0.0, 1.0);
		float tw = size * (0.035 + 0.05 * ty * ty);
		float trunk = step(abs(x - cx - lean * (1.0 - ty) * size * 0.4), tw) * step(top + size * 0.15, y) * step(y, base + 0.2);
		m = max(m, trunk);
		if (h3 < 0.2) {
			// 枯樹：幾根往上斜的尖枝
			for (int b = 0; b < 3; b++) {
				float by = top + height * (0.2 + 0.22 * float(b));
				float dir = (float(b % 2) * 2.0 - 1.0);
				float along = (by - y) / (height * 0.35);
				float bx = cx + dir * along * size * 0.35;
				float branch = step(0.0, along) * step(along, 1.0) * step(abs(x - bx), size * 0.018 * (1.0 - along));
				m = max(m, branch);
			}
			continue;
		}
		// 樹冠：三團圓，邊緣用雜訊咬出不規則的葉子
		for (int b = 0; b < 3; b++) {
			float hb = hash(vec2(c * 3.0 + float(b), seed + 21.0));
			vec2 cc = vec2(cx + (hb - 0.5) * size * 0.8, top + size * (0.1 + 0.2 * float(b)) * (0.6 + hb * 0.8));
			float r = size * (0.18 + 0.16 * hb) * (1.0 - 0.15 * float(b));
			float edge = (fbm(vec2(x, y) * (14.0 / size) + c) - 0.5) * size * 0.14;
			m = max(m, step(length(vec2(x, y) - cc), r + edge));
		}
	}
	return m;
}

void fragment() {
	vec2 uv = UV;
	float aspect = 1.0 / max(SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y, 0.0001);
	float ax = uv.x * aspect;
	float t = TIME * fog_speed;

	// 天空：上面深藍黑，往地平線變紫
	vec3 col = mix(sky_top, sky_low, smoothstep(0.05, 0.75, uv.y));

	// 星星（只在上半）：一格一顆，有的會閃
	vec2 sc = vec2(ax, uv.y) * 90.0;
	vec2 sid = floor(sc);
	vec2 sf = fract(sc) - 0.5;
	float sh = hash(sid);
	float star = step(0.93, sh) * smoothstep(0.09, 0.0, length(sf - (vec2(hash(sid + 1.3), hash(sid + 7.1)) - 0.5) * 0.6));
	star *= 0.5 + 0.5 * sin(TIME * (1.0 + sh * 3.0) + sh * 40.0);
	col += vec3(0.75, 0.78, 0.95) * star * (1.0 - smoothstep(0.2, 0.6, uv.y)) * 0.8;

	// 月亮：淡黃綠的圓、表面幾塊暗斑、外面一圈光暈
	vec2 md = vec2((uv.x - moon_pos.x) * aspect, uv.y - moon_pos.y);
	float mr = length(md);
	float disc = smoothstep(0.052, 0.049, mr);
	float maria = smoothstep(0.55, 0.7, fbm(md * 38.0 + 3.0)) * 0.22;
	col = mix(col, moon_color * (1.0 - maria), disc);
	col += moon_color * (exp(-mr * mr * 260.0) * 0.22 + exp(-mr * mr * 30.0) * 0.06) * (1.0 - disc);

	// 天上淡淡的雲（被月光照到一點）
	float cloud = smoothstep(0.5, 0.8, fbm(vec2(ax * 1.4 + t * 2.0, uv.y * 4.0)));
	col = mix(col, vec3(0.16, 0.12, 0.22), cloud * 0.25 * (1.0 - smoothstep(0.25, 0.55, uv.y)));

	// 遠的一層樹（被霧吃掉，偏紫）
	float far_m = tree_layer(ax + 0.13, uv.y, 0.075, 0.74, 0.17, 2.0);
	col = mix(col, far_color, far_m * 0.9);

	// 遠樹與中樹之間的瘴氣（一塊一塊地流動、自己發一點紫光）
	float b1 = fbm(vec2(ax * 2.0 + t * 6.0, uv.y * 5.0 - t * 1.2));
	float b2 = fbm(vec2(ax * 4.2 - t * 9.0, uv.y * 8.0 + t * 1.6));
	float bank = smoothstep(0.38, 0.75, b1 * 0.7 + b2 * 0.3);
	float band = smoothstep(0.6, 0.74, uv.y) * (1.0 - smoothstep(0.9, 1.0, uv.y));
	col = mix(col, miasma_color * 0.55, bank * band * 0.6);

	// 中間一層樹（比較大、比較暗）
	float mid_m = tree_layer(ax + 0.41, uv.y, 0.13, 0.88, 0.34, 5.0);
	col = mix(col, mid_color, mid_m);

	// 前景的瘴氣：貼著地面、比較濃、比較快，亮一點
	float g1 = fbm(vec2(ax * 3.0 + t * 12.0, uv.y * 6.0 - t * 2.5));
	float ground_fog = smoothstep(0.36, 0.78, g1) * smoothstep(0.76, 0.98, uv.y);
	col = mix(col, miasma_color * 0.7, ground_fog * 0.5);

	// 最近的一層：畫面兩邊各一根粗樹幹框住畫面（樹冠在畫面外），中間是低低的土丘與草
	float rx = aspect - ax;
	float left_trunk = step(uv.x * aspect, 0.035 + 0.05 * uv.y * uv.y + (noise(vec2(uv.y * 9.0, 1.0)) - 0.5) * 0.012);
	float right_trunk = step(rx, 0.05 + 0.07 * uv.y * uv.y + (noise(vec2(uv.y * 8.0, 5.0)) - 0.5) * 0.014);
	float near_m = max(left_trunk, right_trunk);
	float mound = 0.93 - 0.03 * sin(ax * 3.1 + 0.7) - 0.02 * sin(ax * 7.3);
	float grass = (fbm(vec2(ax * 60.0, 0.0)) - 0.5) * 0.03;
	float ground_m = step(mound + grass, uv.y);
	col = mix(col, near_color, max(near_m, ground_m));

	// 夜光毒蕈：土丘上幾朵，青色的蕈傘＋一圈光
	for (int i = 0; i < 7; i++) {
		float fi = float(i);
		float mx = (0.12 + fi * 0.13 + (hash(vec2(fi, 4.0)) - 0.5) * 0.08) * aspect;
		float my = 0.93 - 0.03 * sin(mx * 3.1 + 0.7) - 0.02 * sin(mx * 7.3) + 0.004;
		float s = 0.008 + hash(vec2(fi, 8.0)) * 0.007;
		vec2 d = vec2(ax - mx, uv.y - my);
		float cap = step(length(d * vec2(1.0, 1.8)), s) * step(d.y, 0.0);
		float stem = step(abs(d.x), s * 0.22) * step(0.0, d.y) * step(d.y, s * 1.2);
		float pulse = 0.8 + 0.2 * sin(TIME * 1.3 + fi * 2.1);
		col = mix(col, mushroom_color * pulse, cap);
		col = mix(col, mushroom_color * 0.35, stem);
		col += mushroom_color * exp(-dot(d, d) / (s * s * 9.0)) * 0.22 * pulse;
	}

	// 從瘴氣裡往上飄的光點：下面是紫的，飄過一半翻成金色（翻的那一下亮一點）
	for (int i = 0; i < 26; i++) {
		float fi = float(i);
		float h1 = hash(vec2(fi, 1.0));
		float h2 = hash(vec2(fi, 2.0));
		float h3 = hash(vec2(fi, 3.0));
		float life = fract(TIME * (0.035 + h2 * 0.04) + h1);
		float py = 0.98 - life * 0.75;
		float px = (0.08 + h3 * 0.9) * aspect + sin(TIME * (0.6 + h2) + fi) * 0.012;
		vec2 d = vec2(ax - px, uv.y - py);
		float r2 = dot(d, d);
		float turn = smoothstep(0.72, 0.62, py);
		float flash = exp(-pow((py - 0.67) / 0.02, 2.0)) * 1.5;
		vec3 c = mix(curse_color, gold_color, turn);
		float fade = smoothstep(0.0, 0.08, life) * (1.0 - smoothstep(0.75, 1.0, life));
		float size = 0.0025 + h2 * 0.002;
		col += c * fade * (exp(-r2 / (size * size)) * (1.2 + flash) + exp(-r2 / (size * size * 25.0)) * 0.15);
	}

	// 左邊的標題字：壓暗一點；暗角
	col *= mix(0.62, 1.0, smoothstep(0.05, 0.6, uv.x));
	vec2 v = uv - 0.5;
	col *= 1.0 - dot(v, v) * 1.1;

	// 微弱顆粒，避免色帶
	col += (hash(uv * 1024.0 + TIME) - 0.5) * 0.012;
	COLOR = vec4(col, 1.0);
}
