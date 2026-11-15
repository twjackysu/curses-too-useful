shader_type spatial;
// 蓋在身體上的一層加法光：邊緣（視線擦過的地方）最亮，正面可以再墊一層底色（fill）。兩個地方在用：
// ・硬撐的紅光（EnemyActor，掛在 material_overlay）：「該閃了」的訊號要大到整個輪廓都是紅的——
//   遠看是一個紅色的人形，近看是一圈紅邊。
// ・劇毒史萊姆的綠邊（Slime，掛在材質的 next_pass，fill 0、rim_power 大）：細細的一圈，從紫霧裡看得出牠在哪。
// strength 由程式每幀寫（硬撐：剛變紅的那一下最亮、之後一下一下跳、擺前兆時再往上；史萊姆：蓄力時變亮）。
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;

uniform vec3 glow_color : source_color = vec3(1.0, 0.16, 0.05);
uniform float fill = 0.55;
uniform float rim = 2.6;
uniform float rim_power = 1.8;
uniform float strength = 1.0;
// 貼在鏡頭上的時候跟著身體一起淡掉（身體是抖動淡出，CameraFade；這一層不淡的話會剩一個紅色的殘影）
uniform float fade_near = 0.4;
uniform float fade_far = 1.0;

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float edge = pow(1.0 - facing, rim_power);
	float near_fade = smoothstep(fade_near, fade_far, length(VERTEX));
	ALBEDO = glow_color * (fill + rim * edge) * strength * near_fade;
}
