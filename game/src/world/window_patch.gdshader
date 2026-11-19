shader_type spatial;
// 窗落在地上的那一格一格的光（WindowLight）：UV＝窗上的位置（0～1；平行投影，所以直接內插就對），
// 照窗框與窗櫺（跟 guild_window.gdshader 一樣的比例）畫亮的格子，邊緣柔一點。加法、不受光、貼在地板上面。
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 color : source_color = vec3(1.0, 0.9, 0.68);
uniform float energy = 0.5;
uniform vec2 panes = vec2(3.0, 4.0);
uniform vec2 frame = vec2(0.06, 0.045);

float soft_cell(float g, float n) {
	float c = fract(g * n);
	return smoothstep(0.02, 0.16, c) * smoothstep(0.98, 0.84, c) * smoothstep(-0.02, 0.03, g) * smoothstep(1.02, 0.97, g);
}

void fragment() {
	vec2 g = (UV - frame) / (1.0 - 2.0 * frame);
	float glass = soft_cell(g.x, panes.x) * soft_cell(g.y, panes.y);
	// 靠窗台的那一頭（UV.y＝1，窗的下緣落得最近）亮一點，遠的那一頭淡一點
	float fade = 0.7 + 0.3 * UV.y;
	ALBEDO = color * energy * glass * fade;
}
