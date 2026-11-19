shader_type spatial;
// 窗照進來的光柱（WindowLight）：從窗口一路掃到地上的好幾片薄面，疊起來看起來像一道有體積的光。
// UV.x＝從窗口（0）到地上（1）；UV.y＝這一片在窗上的位置（直的面片是窗的高度、橫的面片是窗的寬度），
// 照窗櫺的位置畫暗縫——一格一格的玻璃各自一道光柱。加法、不受光、不寫深度；
// 側對鏡頭的面片會淡掉（不然是一條亮線），碰到地板、桌子的地方淡掉（不會有一道切得很硬的邊），鏡頭走進光裡也淡掉。
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 color : source_color = vec3(1.0, 0.9, 0.68);
uniform float energy = 0.05;
// 這個方向有幾格玻璃、玻璃外面那一圈木框佔多少（UV.y 的兩頭）
uniform float cells = 4.0;
uniform float frame = 0.045;
uniform sampler2D depth_tex : hint_depth_texture, filter_linear_mipmap;

void fragment() {
	float g = (UV.y - frame) / (1.0 - 2.0 * frame);
	float c = fract(g * cells);
	float glass = smoothstep(0.03, 0.14, c) * smoothstep(0.97, 0.86, c) * step(0.0, g) * step(g, 1.0);
	// 靠窗口最亮，往地上淡到沒有（落在地上的那一格一格交給 WindowLight 的聚光燈）；剛出窗口的那一小段淡進來
	float along = smoothstep(0.0, 0.06, UV.x) * (1.0 - smoothstep(0.5, 1.0, UV.x)) * (1.0 - 0.35 * UV.x);
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float side = smoothstep(0.08, 0.45, facing);
	// 跟後面的東西（地板、桌子、人）靠得很近的地方淡掉
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 behind = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	behind.xyz /= behind.w;
	float soft = clamp((VERTEX.z - behind.z) / 0.35, 0.0, 1.0);
	float near_cam = smoothstep(0.6, 2.4, -VERTEX.z);
	ALBEDO = color * energy * glass * along * side * soft * near_cam;
}
