shader_type spatial;
// 公會大廳的牆（一片朝屋裡的面；背面不畫，鏡頭退到牆外的時候看得進來）：下面一截深色的直木板護牆、上面米色的灰泥，
// 每隔 bay 公尺一根木柱、腰上一道橫木、頂上一道樑——木骨架是畫上去的，沒有另外的模型（鏡頭在牆外時才不會看到它們的背面）。
// 位置照世界座標算：東西向的牆用 Z 當橫的方向，南北向的牆用 X。

uniform float height = 6.4;
// 木柱的間距與位移（公尺）：南北向的牆把柱子錯開，門才會落在兩根柱子中間
uniform float bay = 5.0;
uniform float shift = 0.0;
uniform vec3 plaster : source_color = vec3(0.78, 0.69, 0.54);
uniform vec3 timber : source_color = vec3(0.26, 0.16, 0.1);
uniform vec3 panel : source_color = vec3(0.36, 0.23, 0.14);

varying vec3 world_pos;
varying vec3 world_n;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float s = abs(world_n.x) > 0.5 ? world_pos.z : world_pos.x;
	float y = world_pos.y;
	// 灰泥：大塊的深淺＋細的顆粒，越靠天花板越暗（被煙燻過）
	vec3 col = plaster * (0.86 + 0.2 * noise(vec2(s, y) * 0.9) + 0.06 * noise(vec2(s, y) * 9.0));
	col *= mix(1.0, 0.72, smoothstep(height * 0.55, height, y));
	// 木骨架：柱、腰上的橫木、頂樑
	float post = abs(fract((s + shift) / bay + 0.5) - 0.5) * bay;
	float frame = 1.0 - smoothstep(0.13, 0.15, post);
	frame = max(frame, 1.0 - smoothstep(0.1, 0.12, abs(y - 3.45)));
	frame = max(frame, smoothstep(height - 0.36, height - 0.34, y));
	float fibre = noise(vec2(s * 14.0, y * 1.5)) * (1.0 - step(0.14, post)) + noise(vec2(s * 1.5, y * 14.0)) * step(0.14, post);
	col = mix(col, timber * (0.8 + 0.4 * fibre), frame);
	// 護牆板：直的木板，上面壓一條深色的收邊
	if (y < 1.2) {
		float u = s / 0.24;
		float fu = fract(u);
		float tone = hash(vec2(floor(u), 5.0));
		vec3 wood = panel * (0.78 + 0.34 * tone) * (0.9 + 0.2 * noise(vec2(u * 8.0, y * 1.6 + tone * 30.0)));
		wood *= mix(0.45, 1.0, smoothstep(0.0, 0.05, fu) * smoothstep(1.0, 0.95, fu));
		col = mix(wood, timber * 0.9, smoothstep(1.08, 1.1, y));
		col = mix(col, timber * 0.8, 1.0 - smoothstep(0.1, 0.12, y));
	}
	ALBEDO = col;
	ROUGHNESS = 0.92;
	SPECULAR = 0.1;
}
