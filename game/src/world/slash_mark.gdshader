shader_type spatial;
// 刀痕（SlashMark）：一條兩頭尖的亮線。UV.x 沿著刀痕、UV.y 是寬；中間最寬、有一條最亮的芯。
// 畫在身體前面（不做深度測試）：命中點貼著敵人，做深度測試會被身體切掉一半。
render_mode unshaded, blend_add, cull_disabled, depth_test_disabled, shadows_disabled;

uniform vec3 tint : source_color = vec3(0.9, 0.36, 0.18);
uniform vec3 core : source_color = vec3(1.0, 0.85, 0.7);
uniform float strength = 1.0;
// 1＝剛砍下去，0＝淡完了
uniform float fade = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float taper = max(1.0 - p.x * p.x, 0.001);
	float w = abs(p.y) / taper;
	float body = smoothstep(1.0, 0.1, w);
	float hot = smoothstep(0.4, 0.0, w);
	ALBEDO = (tint * body * body + core * hot) * strength * fade * smoothstep(0.0, 0.2, taper);
}
