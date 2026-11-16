shader_type spatial;
// 公會大廳的木頭（地板、天花板、樑、迴廊、樓梯、門）：照世界座標畫一條一條的木板——每一條深淺不同、有木紋，
// 板與板之間一道暗縫，長邊每隔幾公尺錯開一道接縫。木板順著 `along` 的方向（地板順著 Z、橫樑順著 X、門板順著 Y）；
// 板寬的方向由那一面的法線決定，所以同一個材質可以用在盒子的每一面。
// wear：地板中間那條走道被踩得比較亮（x 靠近 0 的地方；不是地板就設 0）。

uniform vec3 tint : source_color = vec3(0.42, 0.27, 0.16);
// 一條木板多寬、一塊多長（公尺）
uniform float plank = 0.26;
uniform float board_len = 3.2;
uniform vec3 along = vec3(0.0, 0.0, 1.0);
uniform float wear = 0.0;
uniform float rough = 0.85;

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
	vec3 a = normalize(along);
	vec3 across = cross(n, a);
	// 木頭的斷面（法線跟長邊同一個方向）：隨便挑一個方向當板寬
	if (length(across) < 0.05) {
		across = cross(n, vec3(0.31, 0.77, 0.55));
	}
	across = normalize(across);
	float u = dot(world_pos, across) / plank;
	float row = floor(u);
	float v = dot(world_pos, a) / board_len + hash(vec2(row, 3.7));
	float tone = hash(vec2(row, floor(v)));
	float fu = fract(u);
	float fv = fract(v);
	float seam = smoothstep(0.0, 0.04, fu) * smoothstep(1.0, 0.96, fu) * smoothstep(0.0, 0.006, fv) * smoothstep(1.0, 0.994, fv);
	float grain = noise(vec2(u * 9.0, dot(world_pos, a) * 1.4 + tone * 40.0));
	vec3 col = tint * (0.76 + 0.36 * tone) * (0.9 + 0.2 * grain);
	col *= mix(0.42, 1.0, seam);
	col *= 1.0 + wear * 0.3 * exp(-world_pos.x * world_pos.x / 2.6);
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.2;
}
