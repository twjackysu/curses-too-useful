shader_type spatial;
// 噴發口腳下那一圈往外裂的地縫（ForestExplore.vent_rim）：從洞口往外七八道彎彎的綠縫，越外面越細、越淡，洞口一團亮；
// 一下一下地亮（跟著噴氣的節奏）。加法、不受光：從玩的距離隔著紫霧也看得出「這裡有個會噴毒的洞」。
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec3 color : source_color = vec3(0.45, 1.0, 0.3);
uniform float energy = 3.2;
uniform float lines = 8.0;

float hash(float n) { return fract(sin(n) * 43758.5453); }
float noise1(float x) {
	float i = floor(x);
	float f = fract(x);
	return mix(hash(i), hash(i + 1.0), f * f * (3.0 - 2.0 * f));
}

void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	float r = length(c);
	if (r > 1.0) { discard; }
	float a = atan(c.y, c.x) / 6.2831853 + 0.5;
	float k = floor(a * lines);
	// 每一道縫順著半徑彎一點、長短不一
	float t = a * lines + (noise1(r * 5.0 + k * 3.7) - 0.5) * 0.7;
	float d = abs(fract(t) - 0.5) / lines * 6.2831853 * max(r, 0.05);
	float width = mix(0.1, 0.022, r);
	float crack = 1.0 - smoothstep(width * 0.5, width, d);
	float reach = 1.0 - smoothstep(0.3, 0.55 + 0.45 * hash(k + 11.0), r);
	float core = 1.0 - smoothstep(0.0, 0.3, r);
	float pulse = 0.7 + 0.3 * sin(TIME * 2.4);
	ALBEDO = color * (crack * reach + core * 0.7) * energy * pulse;
}
