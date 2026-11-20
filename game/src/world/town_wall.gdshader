shader_type spatial;
// 賒帳街的城牆與東門的石塔（TownScenery）：一層一層錯開的石塊，每塊深淺不同、縫是深色的，牆腳濺到泥。
// 位置照世界座標算（牆是直的盒子：沿著牆的方向取 x 或 z，看這一面朝哪）。

uniform vec3 stone : source_color = vec3(0.62, 0.6, 0.56);
// 一層多高、一塊多長（公尺）
uniform float course = 0.55;
uniform float block = 1.15;

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
	vec3 col = stone * 0.82;
	if (abs(world_n.y) < 0.5) {
		float s = abs(world_n.x) > 0.5 ? world_pos.z : world_pos.x;
		float row = floor(world_pos.y / course);
		vec2 q = vec2(s / block + 0.5 * mod(row, 2.0) + 0.17 * hash(vec2(row, 5.0)), world_pos.y / course);
		vec2 id = floor(q);
		vec2 f = fract(q);
		float gap = smoothstep(0.02, 0.07, min(min(f.x, 1.0 - f.x) * block, min(f.y, 1.0 - f.y) * course));
		col = stone * (0.76 + 0.36 * hash(id)) * (0.9 + 0.2 * noise(vec2(s, world_pos.y) * 2.1));
		col = mix(stone * 0.38, col, gap);
		col *= mix(0.74, 1.0, smoothstep(0.15, 1.3, world_pos.y));
	}
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}
