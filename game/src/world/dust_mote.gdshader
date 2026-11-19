shader_type spatial;
// 光柱裡飄的灰塵（WindowLight）：一顆一顆面向鏡頭的小亮點（MultiMesh 的每一個實例），慢慢地飄、一閃一閃。
// 只擺在光柱裡面，所以看起來是被光照到才看得見的灰塵。加法、不受光。
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 color : source_color = vec3(1.0, 0.9, 0.7);
uniform float energy = 0.8;
// 飄多遠（公尺）
uniform float wander = 0.18;

varying float seed;

void vertex() {
	seed = fract(sin(float(INSTANCE_ID) * 12.9898) * 43758.5453);
	vec3 drift = vec3(sin(TIME * 0.31 + seed * 6.28), 0.6 * sin(TIME * 0.17 + seed * 3.1), cos(TIME * 0.23 + seed * 5.0)) * wander;
	vec3 origin = MODEL_MATRIX[3].xyz + drift;
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, vec4(origin, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float dot_ = 1.0 - smoothstep(0.0, 1.0, d);
	float twinkle = 0.45 + 0.55 * (0.5 + 0.5 * sin(TIME * (1.2 + seed) + seed * 20.0));
	ALBEDO = color * energy * dot_ * dot_ * twinkle;
}
