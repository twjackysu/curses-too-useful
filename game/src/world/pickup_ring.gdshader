shader_type spatial;
// 「這個可以拿」的地面光圈（ForestScenery.pickup_ring）：平放在可以採的毒蕈、可以吃的野果腳下，
// 一圈慢慢往外擴、淡掉，再從裡面冒一圈——跟路邊當擺設、長得一樣的毒蕈與灌木分得出來。
// fog_disabled：加法混色的面片吃到霧，整片（連沒有光的四個角）會加上一層霧的顏色，看得出是一塊方的。
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 color : source_color = vec3(0.45, 0.95, 1.0);
uniform float strength = 0.9;
uniform float speed = 0.55;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	// 一圈往外擴：t 從 0 到 1，半徑從 0.35 擴到 0.95、越外面越淡
	float t = fract(TIME * speed);
	float wave = 1.0 - smoothstep(0.0, 0.07, abs(r - mix(0.35, 0.95, t)));
	wave *= 1.0 - t;
	// 不動的一圈細邊＋中間一點淡淡的底
	float rim = (1.0 - smoothstep(0.0, 0.035, abs(r - 0.8))) * 0.45;
	float core = (1.0 - smoothstep(0.0, 0.7, r)) * 0.18;
	float a = (wave + rim + core) * (1.0 - smoothstep(0.92, 1.0, r));
	ALBEDO = color * a * strength;
}
