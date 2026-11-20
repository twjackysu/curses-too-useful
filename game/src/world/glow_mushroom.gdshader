shader_type spatial;
// 夜光毒蕈的顏色。Tripo 那個模型的顏色貼圖是一張灰的（生成時顏色沒有畫上去），直接用整叢是一片白，
// 所以顏色照形狀算：朝上的面是蕈傘（傘頂紫、往邊緣偏藍綠，上面有會亮的青色斑點）、
// 朝下的面是蕈褶（發青光）、直的面是蕈柄（淡青）、貼地的一圈是苔。
// 原本的灰貼圖只拿來當表面的明暗細節，法線貼圖照用。斑點的位置用世界座標算，每一叢都不一樣。
// 直的面光看法線分不出是蕈傘的側邊還是蕈柄（以前傘的邊緣是一圈淡青）：轉檔時在頂點色記了每一點往上看不看得到天空
// （tripo_prop.py --sky-mask；R＝1 看得到）——看得到天空的直的面是傘的邊緣，塗傘的顏色；被傘擋住的才是蕈柄。

uniform sampler2D detail : filter_linear_mipmap, repeat_enable, hint_default_white;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float ground_y = 0.0;
uniform float spot_size = 0.1;
uniform float glow = 1.0;
uniform float has_sky = 0.0;   // 模型有沒有記天空的頂點色（替身與舊的模型沒有：照以前只看法線）

varying vec3 world_pos;
varying vec3 world_n;
varying float sky;

vec3 hash3(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5, 183.3, 246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453);
}

// 離最近的斑點中心多遠（一格一顆，格子邊長 1）
float spot_dist(vec3 p) {
	vec3 cell = floor(p);
	float best = 9.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				vec3 c = cell + vec3(float(x), float(y), float(z));
				best = min(best, distance(p, c + hash3(c)));
			}
		}
	}
	return best;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	sky = COLOR.r;
}

void fragment() {
	vec3 n = normalize(world_n);
	float gill = smoothstep(-0.1, -0.55, n.y);
	float rim = has_sky * smoothstep(0.35, 0.85, sky) * (1.0 - gill);
	float cap = max(smoothstep(0.1, 0.55, n.y), rim);
	float moss = 1.0 - smoothstep(0.05, 0.16, world_pos.y - ground_y);
	vec3 cap_col = mix(vec3(0.27, 0.12, 0.66), vec3(0.12, 0.36, 0.7), smoothstep(0.8, 0.3, n.y));
	vec3 col = mix(vec3(0.5, 0.82, 0.88), cap_col, cap);
	col = mix(col, vec3(0.3, 0.9, 0.85), gill);
	float spot = cap * smoothstep(0.32, 0.22, spot_dist(world_pos / spot_size));
	col = mix(col, vec3(0.25, 1.0, 0.9), spot);
	float patch = step(0.5, fract(sin(dot(floor(world_pos.xz * 9.0), vec2(12.9898, 78.233))) * 43758.5453));
	col = mix(col, mix(vec3(0.16, 0.26, 0.12), vec3(0.28, 0.2, 0.13), patch), moss);
	ALBEDO = col * mix(0.8, 1.1, texture(detail, UV).r);
	ROUGHNESS = 0.55;
	NORMAL_MAP = texture(normal_map, UV).rgb;
	EMISSION = col * (0.14 + 0.1 * (1.0 - cap) + 1.1 * gill + 1.1 * spot) * (1.0 - moss) * glow;
}
