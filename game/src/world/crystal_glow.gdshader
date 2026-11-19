shader_type spatial;
// 公會的適性測試水晶（GuildScenery）：蓋在水晶球外面的那一層光。加法、不受光，中間淡、輪廓一圈亮（像光從玻璃裡面透出來）。
// 以前是整顆球一樣亮的加法色：警報的紅 ×5 之後綠與藍也有 0.8，過了色調映射變成粉白。現在顏色只給純的紅／藍，
// 亮度壓在 1 附近，亮的感覺交給輪廓那一圈與 glow——紅的才會是紅的。
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec3 color : source_color = vec3(0.35, 0.7, 1.0);
uniform float energy = 1.0;

void fragment() {
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - facing, 2.2);
	ALBEDO = color * energy * (0.22 + 1.5 * rim);
}
