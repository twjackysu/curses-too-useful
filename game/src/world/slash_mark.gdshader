shader_type spatial;
// 刀痕（SlashMark）：一條兩頭尖的亮線。UV.x 沿著刀痕、UV.y 是寬；中間最寬、有一條最亮的芯。
// 命中點貼著敵人，照原位做深度測試會被牠的身體切掉一半；整個不測又會畫到站在鏡頭與敵人中間的諾恩身上。
// 所以沿著視線往鏡頭拉近 pull 公尺再測：畫面上的位置不變，敵人的身體擋不到，比那更靠近鏡頭的人擋得到。
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 tint : source_color = vec3(0.9, 0.36, 0.18);
uniform vec3 core : source_color = vec3(1.0, 0.85, 0.7);
uniform float strength = 1.0;
// 1＝剛砍下去，0＝淡完了
uniform float fade = 1.0;
// 拉近幾公尺：被砍的那一隻的身體半徑多一點（SlashMark.set_pull）
uniform float pull = 0.12;

void vertex() {
	vec4 v = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float d = max(length(v.xyz), 0.001);
	v.xyz *= max(d - pull, 0.2) / d;
	POSITION = PROJECTION_MATRIX * v;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float taper = max(1.0 - p.x * p.x, 0.001);
	float w = abs(p.y) / taper;
	float body = smoothstep(1.0, 0.1, w);
	float hot = smoothstep(0.4, 0.0, w);
	ALBEDO = (tint * body * body + core * hot) * strength * fade * smoothstep(0.0, 0.2, taper);
}
