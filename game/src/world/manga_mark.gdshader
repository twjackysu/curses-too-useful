shader_type spatial;
// 漫符：講話的人頭上冒出來的符號（汗、怒筋、閃亮、臉紅、驚嚇線、陰影線、問號），一律面向鏡頭、深色描邊。
// 形狀全用距離場畫（d < 0 在裡面），描邊＝往外 OUTLINE 那一圈；邊緣用 fwidth 抗鋸齒。
// 畫的時候往鏡頭拉近 pull 公尺（只改深度）：貼在臉上的（臉紅、陰影線）不會插進頭髮裡被切掉。
// kind：0 汗 1 怒筋 2 閃亮 3 臉紅 4 驚嚇線 5 陰影線 6 問號（順序跟 MangaMark.KINDS 一樣）
// 顏色照畫面上看到的（sRGB）寫，最後換成線性（不換的話紅色的怒筋畫出來是粉紅色）。
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform int kind = 0;
// 冒出來多久了（秒）：閃亮一閃一閃、怒筋一跳一跳、陰影線往下垂
uniform float age = 0.0;
// 整體透明度（冒出來、收起來時由程式給）
uniform float alpha = 1.0;
uniform float pull = 0.25;

const float OUTLINE = 0.075;
const vec3 INK = vec3(0.08, 0.06, 0.12);

void vertex() {
	mat4 mv = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	mv = mv * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	vec4 vp = mv * vec4(VERTEX, 1.0);
	vp.xyz *= max(1.0 - pull / max(length(vp.xyz), 0.001), 0.2);
	POSITION = PROJECTION_MATRIX * vp;
}

// 一頭粗一頭細的膠囊（iq）：r1 的圓在原點、r2 的圓在 (0, h)。r2 很小就是一滴水
float uneven_capsule(vec2 p, float r1, float r2, float h) {
	p.x = abs(p.x);
	float b = (r1 - r2) / h;
	float a = sqrt(1.0 - b * b);
	float k = dot(p, vec2(-b, a));
	if (k < 0.0) {
		return length(p) - r1;
	}
	if (k > a * h) {
		return length(p - vec2(0.0, h)) - r2;
	}
	return dot(p, vec2(a, b)) - r1;
}

float segment(vec2 p, vec2 a, vec2 b, float r) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - r;
}

// 往兩頭變細的一劃（驚嚇線、陰影線）
float stroke(vec2 p, vec2 a, vec2 b, float r) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - r * (0.35 + 0.65 * sin(h * 3.14159));
}

// 四角星（閃亮）：|x|^0.5 + |y|^0.5，不是真的距離，夠用
float star(vec2 p, vec2 c, float r) {
	vec2 q = abs(p - c) / r;
	return (sqrt(q.x) + sqrt(q.y) - 1.0) * r * 0.5;
}

float ellipse(vec2 p, vec2 c, vec2 r) {
	vec2 q = (p - c) / r;
	return (length(q) - 1.0) * min(r.x, r.y);
}

vec3 to_linear(vec3 c) {
	return pow(c, vec3(2.2));
}

void fragment() {
	vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y * 2.0);
	float d = 1.0;
	vec3 fill = vec3(1.0);
	vec3 ink = INK;
	float soft = 0.0;  // 臉紅與陰影線：沒有描邊、半透明
	float extra = 0.0; // 疊在上面的亮點
	if (kind == 0) {
		// 汗：一滴往上尖的水，淺藍、左下一點反光
		d = uneven_capsule(p - vec2(0.0, -0.42), 0.42, 0.05, 1.12);
		fill = vec3(0.62, 0.86, 1.0);
		ink = vec3(0.1, 0.22, 0.5);
		extra = step(ellipse(p, vec2(-0.14, -0.36), vec2(0.1, 0.15)), 0.0);
	} else if (kind == 1) {
		// 怒筋：四段弧，凸的一面朝中心；一跳一跳
		float beat = 1.0 + 0.12 * max(sin(age * 9.0), 0.0);
		vec2 q = abs(p) * beat;
		float ring = abs(length(q - vec2(0.68)) - 0.46) - 0.1;
		d = max(ring, max(q.x, q.y) - 0.68);
		fill = vec3(0.95, 0.16, 0.2);
		ink = vec3(0.3, 0.02, 0.05);
	} else if (kind == 2) {
		// 閃亮：一大兩小的四角星，輪流一閃一閃
		float tw0 = 0.85 + 0.15 * sin(age * 7.0);
		float tw1 = 0.6 + 0.4 * sin(age * 7.0 + 2.1);
		float tw2 = 0.6 + 0.4 * sin(age * 7.0 + 4.2);
		d = min(star(p, vec2(0.08, 0.05), 0.72 * tw0), min(star(p, vec2(-0.58, 0.55), 0.32 * tw1), star(p, vec2(0.62, -0.6), 0.28 * tw2)));
		fill = vec3(1.0, 0.98, 0.8);
		ink = vec3(0.95, 0.62, 0.12);
	} else if (kind == 3) {
		// 臉紅：兩頰各一塊粉紅的橢圓，上面三道斜線
		soft = 1.0;
		float cheeks = min(ellipse(p, vec2(-0.52, 0.0), vec2(0.34, 0.17)), ellipse(p, vec2(0.52, 0.0), vec2(0.34, 0.17)));
		vec2 c = vec2(abs(p.x) - 0.52, p.y);
		float lines = 1.0;
		for (int i = -1; i <= 1; i++) {
			float x = float(i) * 0.16;
			lines = min(lines, segment(c, vec2(x + 0.06, 0.1), vec2(x - 0.06, -0.1), 0.022));
		}
		float blush_a = smoothstep(0.06, -0.04, cheeks) * 0.55;
		float line_a = smoothstep(fwidth(lines), 0.0, lines) * 0.9;
		ALBEDO = to_linear(mix(vec3(1.0, 0.45, 0.55), vec3(0.85, 0.15, 0.3), line_a));
		ALPHA = max(blush_a, line_a) * alpha;
	} else if (kind == 4) {
		// 驚嚇線：頭頂往外炸開的三劃
		d = 1.0;
		for (int i = 0; i < 3; i++) {
			float ang = radians(55.0 + 35.0 * float(i));
			vec2 dir = vec2(cos(ang), sin(ang));
			vec2 base = vec2(0.0, -0.75);
			d = min(d, stroke(p, base + dir * 0.55, base + dir * 1.55, 0.13));
		}
		fill = vec3(1.0, 0.96, 0.7);
	} else if (kind == 5) {
		// 陰影線：額頭上一排往下垂的直線，越往下越淡
		soft = 1.0;
		float grow = clamp(age * 1.6, 0.0, 1.0);
		float lines = 1.0;
		for (int i = -3; i <= 3; i++) {
			float x = float(i) * 0.2;
			float len = (0.9 + 0.5 * fract(sin(float(i) * 12.9) * 43.7)) * grow;
			lines = min(lines, segment(p, vec2(x, 0.9), vec2(x, 0.9 - len), 0.03));
		}
		float fade = smoothstep(-0.9, 0.6, p.y);
		ALBEDO = to_linear(vec3(0.22, 0.18, 0.42));
		ALPHA = smoothstep(fwidth(lines), 0.0, lines) * fade * 0.75 * alpha;
	} else {
		// 問號：上面一段彎、下面一點
		vec2 c = p - vec2(0.0, 0.36);
		float ring = abs(length(c) - 0.34) - 0.12;
		float ang = atan(c.y, c.x);
		// 左下那一段不要（從 -90° 到 -170°）
		float cut = (ang < -1.57 && ang > -2.97) ? 1.0 : 0.0;
		ring = mix(ring, 1.0, cut);
		float stem = segment(p, vec2(0.0, 0.02), vec2(0.0, -0.22), 0.12);
		float dotp = length(p - vec2(0.0, -0.62)) - 0.15;
		d = min(min(ring, stem), dotp);
		fill = vec3(1.0);
	}
	if (soft < 0.5) {
		float aa = max(fwidth(d), 0.002);
		float inside = smoothstep(aa, -aa, d);
		float outer = smoothstep(OUTLINE + aa, OUTLINE - aa, d);
		ALBEDO = to_linear(mix(ink, mix(fill, vec3(1.0), extra), inside));
		ALPHA = outer * alpha;
	}
}
