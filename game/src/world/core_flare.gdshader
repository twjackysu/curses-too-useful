shader_type spatial;
// 魔像身上會亮的那一點（胸口的核心、擺石化凝視時的眼睛）：面向鏡頭的一片加法光。中間一顆亮點、一圈光暈、幾道慢慢轉的光芒；
// open＝1（核心可以粉碎了）多一圈一圈往中心收的環——「砍這裡」。顏色與亮度由程式給。
// 畫的時候往鏡頭拉近 pull 公尺（只改深度，畫面上的位置與大小不變）：光片插在凹凸的石頭身體裡，不拉近會被切成一塊一塊；
// 站在牠前面的人照樣擋得住。
// fog_disabled：加法混色的面片吃到霧的話，整片（連沒有光的四個角）都會加上一層霧的顏色，看得出是一塊方的。
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 flare_color : source_color = vec3(0.72, 0.42, 1.0);
uniform float strength = 1.0;
uniform float open = 0.0;
uniform float pull = 0.8;

void vertex() {
	// 面向鏡頭、保留縮放
	mat4 mv = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	mv = mv * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	vec4 vp = mv * vec4(VERTEX, 1.0);
	vp.xyz *= max(1.0 - pull / max(length(vp.xyz), 0.001), 0.2);
	POSITION = PROJECTION_MATRIX * vp;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float dot_core = exp(-r * r * 26.0);
	float halo = exp(-r * r * 4.5) * 0.3;
	float rays = pow(abs(sin(a * 2.0 + TIME * 0.5)), 18.0) * exp(-r * 2.4)
		+ pow(abs(sin(a * 3.0 - TIME * 0.8 + 1.0)), 26.0) * exp(-r * 3.6) * 0.6;
	// 往中心收的環：從外面縮到中心，越接近中心越亮
	float t = fract(TIME * 1.5);
	float ring_r = mix(0.92, 0.12, t);
	float ring = smoothstep(0.06, 0.0, abs(r - ring_r)) * smoothstep(0.0, 0.25, t) * open;
	float edge = smoothstep(1.0, 0.75, r);
	ALBEDO = flare_color * (dot_core * 2.2 + halo + rays * (0.6 + 0.9 * open) + ring * 1.6) * strength * edge;
}
