shader_type spatial;
// 諾恩身上的黑氣纏著身體繞的那幾條（DarkAura 的 Wisps）：一條一條螺旋的帶子，
// 沿著帶子往上流的雜訊切成一縷一縷的煙；頭尾淡掉、帶子兩邊淡掉。COLOR.r 是第幾條（雜訊錯開）。
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.1, 0.03, 0.16, 0.85);
uniform vec4 edge : source_color = vec4(0.45, 0.16, 0.6, 1.0);
uniform float fade = 0.0;

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

void fragment() {
	float seed = COLOR.r * 17.0;
	float across = 1.0 - abs(UV.y * 2.0 - 1.0);
	float n = noise(vec2(UV.x * 9.0 - TIME * 0.9 + seed, UV.y * 1.5 + seed * 3.0)) * 0.65
			+ noise(vec2(UV.x * 23.0 - TIME * 1.7 + seed, UV.y * 3.0)) * 0.35;
	float wisp = smoothstep(0.36, 0.7, n);
	float ends = smoothstep(0.0, 0.15, UV.x) * (1.0 - smoothstep(0.72, 1.0, UV.x));
	// 一縷的邊緣偏亮紫（暗的大廳裡看得出輪廓）
	float rim = smoothstep(0.36, 0.46, n) * (1.0 - smoothstep(0.46, 0.6, n));
	ALBEDO = mix(tint.rgb, edge.rgb, rim * 0.6);
	ALPHA = clamp(wisp * pow(across, 1.4) * ends * tint.a * fade, 0.0, 1.0);
}
