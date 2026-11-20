shader_type spatial;
// 土坡上的石頭與倒木（SlopeClutter）：程式拼的形狀，顏色照形狀與世界座標算。
// 石頭：紫灰的岩面、一道一道暗的裂縫、朝上的面長苔（跟地面樹腳下的苔同一個顏色）。
// 倒木（is_log = 1）：沿著木頭長的樹皮紋（物件座標的 x 是木頭的長軸）、兩頭的截面是一圈一圈的年輪、朝上的面長苔。

uniform float is_log = 0.0;
uniform vec3 stone : source_color = vec3(0.36, 0.33, 0.42);
uniform vec3 stone_dark : source_color = vec3(0.17, 0.15, 0.21);
uniform vec3 bark : source_color = vec3(0.32, 0.22, 0.22);
uniform vec3 bark_dark : source_color = vec3(0.1, 0.06, 0.08);
uniform vec3 wood : source_color = vec3(0.5, 0.36, 0.3);
uniform vec3 moss : source_color = vec3(0.2, 0.34, 0.25);
uniform float log_radius = 0.35;

varying vec3 world_pos;
varying vec3 world_n;
varying vec3 obj_pos;
varying vec3 obj_n;

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
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.07; a *= 0.5; }
	return v;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	obj_pos = VERTEX;
	obj_n = NORMAL;
}

void fragment() {
	vec3 n = normalize(world_n);
	// 三面投影的雜訊（形狀是隨便拼的，沒有好的 UV）
	vec3 w = abs(n);
	w /= (w.x + w.y + w.z);
	float grain = fbm(world_pos.yz * 2.2) * w.x + fbm(world_pos.xz * 2.2) * w.y + fbm(world_pos.xy * 2.2) * w.z;
	float big = fbm(world_pos.xz * 0.6 + world_pos.y * 0.4);
	vec3 col;
	if (is_log > 0.5) {
		// 樹皮：繞著長軸的角度 → 一條一條直的紋，紋路沿著木頭長的方向微微彎
		float ang = atan(obj_pos.z, obj_pos.y);
		float stripes = noise(vec2(ang * 5.0 + obj_pos.x * 0.6, obj_pos.x * 1.4));
		float groove = smoothstep(0.38, 0.62, stripes);
		col = mix(bark_dark, bark, groove) * (0.8 + 0.4 * grain);
		// 截面（法線順著長軸）：年輪＋放射狀的裂
		float cap = smoothstep(0.75, 0.9, abs(obj_n.x));
		float r = length(obj_pos.yz) / log_radius;
		float rings = 0.5 + 0.5 * sin(r * 34.0 + noise(obj_pos.yz * 9.0) * 3.0);
		vec3 cut = mix(wood * 0.62, wood, rings) * mix(1.0, 0.55, smoothstep(0.82, 1.0, r));
		col = mix(col, cut, cap);
		col = mix(col, bark_dark * 0.6, cap * smoothstep(0.93, 0.98, noise(vec2(ang * 7.0, 3.1))));
	} else {
		col = mix(stone_dark, stone, smoothstep(0.25, 0.7, grain)) * (0.85 + 0.3 * big);
		// 裂縫：細的暗線
		float crack = 1.0 - smoothstep(0.0, 0.035, abs(fbm(world_pos.xz * 1.3 + world_pos.y * 0.9) - 0.5));
		col = mix(col, stone_dark * 0.6, crack * 0.8);
	}
	// 朝上的面長苔，邊緣跟著雜訊咬
	float mossy = smoothstep(0.35, 0.7, n.y + (big - 0.5) * 0.9);
	col = mix(col, moss * (0.75 + 0.5 * grain), mossy);
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
}
