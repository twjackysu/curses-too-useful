shader_type spatial;
// 石化凝視的前兆：地上一道從魔像連到席菈的光帶（面片的 V 方向沿著那條線）。中間亮、兩邊淡出，一格一格的亮紋往席菈那邊流；
// charge（0～1）越接近打出去越亮、流得越快。顏色由程式給：平常是蒼白的紫，諾恩擋在線上的時候是金色。
// 打出去的那道光（從眼睛射到人身上，PlagueGolem._gaze_fx）也用它：solid＝1。
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 beam_color : source_color = vec3(0.74, 0.5, 1.0);
uniform float charge = 0.0;
// 1＝整條一樣亮（打出去的那道光）；0＝一格一格往前流的亮紋（地上的前兆）
uniform float solid = 0.0;

void fragment() {
	float across = 1.0 - smoothstep(0.0, 0.5, abs(UV.x - 0.5));
	float flow = mix(0.55 + 0.45 * sin((UV.y * 14.0 - TIME * mix(3.0, 9.0, charge)) * 3.1416), 1.0, solid);
	float ends = smoothstep(0.0, 0.04, UV.y) * smoothstep(1.0, 0.96, UV.y);
	ALBEDO = beam_color * across * flow * ends * mix(1.2, 3.4, charge);
}
