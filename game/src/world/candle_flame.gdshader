shader_type spatial;
// 火苗（CandleFlame：公會的壁燈、吊燈上的蠟燭）：一片永遠面向鏡頭、但保持直立的面片，中間畫一滴往上尖的火——
// 外圈橘、中間黃白，左右擺、上面的尖一伸一縮——外面一圈淡淡的火光（halo）。加法、不受光，亮的部分交給 glow 糊開。
// pull：整片往鏡頭拉近幾公尺（壁燈的燈籠是一整塊實心的模型，火放在籠子裡會被擋住；拉到籠子前面，從哪個角度看都在燈籠的位置）。
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 outer : source_color = vec3(1.0, 0.42, 0.08);
uniform vec3 inner : source_color = vec3(1.0, 0.86, 0.55);
uniform float energy = 1.6;
uniform float halo = 0.2;
uniform float pull = 0.0;
// 面片比火苗大幾倍（多出來的地方畫火光）
uniform float spread = 1.8;
// 每一盞錯開的相位（不然整排一起擺）
uniform float seed = 0.0;

void vertex() {
	// 只繞 Y 轉向鏡頭（跟 StandardMaterial3D 的 BILLBOARD_FIXED_Y 一樣）
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	POSITION = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0) + vec4(0.0, 0.0, pull, 0.0));
}

void fragment() {
	vec2 fuv = (UV - vec2(0.5)) * spread + vec2(0.5, 0.45);
	vec2 p = fuv * 2.0 - 1.0;
	float y = 1.0 - fuv.y;
	float t = TIME * 7.0 + seed * 13.0;
	// 越往上擺得越多
	p.x += 0.16 * sin(t + y * 4.0) * y + 0.05 * sin(t * 2.3 + seed) * y;
	float tip = 0.86 + 0.1 * sin(t * 1.3 + seed * 3.0);
	float width = 0.62 * pow(clamp(1.0 - y / tip, 0.0, 1.0), 0.75) * smoothstep(0.0, 0.22, y);
	float body = 1.0 - smoothstep(width * 0.55, width + 0.001, abs(p.x));
	body *= smoothstep(0.0, 0.06, y) * step(y, 1.0);
	float core = (1.0 - smoothstep(0.0, width * 0.5 + 0.001, abs(p.x))) * (1.0 - smoothstep(0.15, 0.6, y));
	vec3 col = mix(outer, inner, core);
	float r = length((UV - vec2(0.5, 0.55)) * 2.0);
	float glow = pow(1.0 - smoothstep(0.0, 1.0, r), 2.0) * halo * (0.9 + 0.1 * sin(t * 1.7));
	ALBEDO = col * body * energy * (0.75 + 0.25 * core) + outer * glow;
}
