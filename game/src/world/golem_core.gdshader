shader_type spatial;
// 魔像核心（第一章結尾諾恩扛回公會的那一顆）：暗色的石球，表面一道一道裂縫透出病綠色的光。位置用物件自己的座標算（跟著人動也不會流動）。

uniform vec3 rock : source_color = vec3(0.16, 0.17, 0.21);
uniform vec3 glow : source_color = vec3(0.35, 1.0, 0.55);
uniform float energy = 2.2;

varying vec3 local_pos;

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), u.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), u.x), u.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), u.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), u.x), u.y), u.z);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	float n = noise(local_pos * 9.0) * 0.65 + noise(local_pos * 21.0) * 0.35;
	// 裂縫：雜訊值在 0.5 附近的那幾條細線
	float crack = 1.0 - smoothstep(0.0, 0.045, abs(n - 0.5));
	ALBEDO = rock * (0.75 + 0.5 * noise(local_pos * 30.0));
	ROUGHNESS = 0.85;
	EMISSION = glow * energy * crack;
}
