shader_type spatial;
// 鷹眼（致盲被反轉）砍中的那一下：命中點上一個黃色的準星——一圈＋上下左右四道往內指的短線，面向鏡頭、畫在身體前面。
// 跟「砍在破綻上」的白橘閃光分得開（EnemyActor._hit_fx）。不用貼圖：UV 現算。
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.86, 0.3, 1.0);
uniform float alpha = 1.0;

void vertex() {
	// 看板：轉向鏡頭、保留節點的縮放（準星從大縮到小靠節點的 scale）
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ring = 1.0 - smoothstep(0.035, 0.075, abs(r - 0.72));
	vec2 a = abs(p);
	float h = (1.0 - smoothstep(0.04, 0.08, a.y)) * smoothstep(0.38, 0.42, a.x) * (1.0 - smoothstep(0.94, 0.98, a.x));
	float v = (1.0 - smoothstep(0.04, 0.08, a.x)) * smoothstep(0.38, 0.42, a.y) * (1.0 - smoothstep(0.94, 0.98, a.y));
	ALBEDO = tint.rgb * 1.6;
	ALPHA = clamp(max(ring, max(h, v)), 0.0, 1.0) * alpha;
}
