shader_type spatial;
// 公會的適性測試水晶（GuildScenery）：掛在水晶模型 material_overlay 上的「乘法」一層——把模型本身的顏色染過去。
// 模型的貼圖是偏白的藍玻璃，只靠紅色的燈照，會被暖色的環境光沖成粉紅；乘上去之後警報時整顆是紅的、測完是灰的。
render_mode unshaded, blend_mul, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec3 tint : source_color = vec3(1.0);

void fragment() {
	ALBEDO = tint;
}
