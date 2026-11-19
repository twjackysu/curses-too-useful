shader_type spatial;
// 公會大廳的窗：一片貼在牆前面的面（背面不畫）。深色的木框＋十字窗櫺，一格一格的玻璃自己發光。
// 窗外沒有真的場景：玻璃上畫天色＋街對面房子的剪影（山形屋頂、煙囪，每扇窗照 `seed` 排得不一樣）。
// 受光的那一側（早上東邊、傍晚西邊）天很亮、房子是背光的深色剪影；背光的那一側天是藍的、房子淡一點。`light`、`energy`、`seed` 由 GuildScenery 設。

uniform vec3 light : source_color = vec3(1.0, 0.9, 0.7);
uniform float energy = 2.2;
uniform vec3 frame_color : source_color = vec3(0.2, 0.12, 0.08);
// 房子剪影的顏色（不發光的那一層）與它自己亮多少（相對於天）
uniform vec3 house_color : source_color = vec3(0.3, 0.24, 0.26);
uniform float house_glow = 0.16;
uniform float seed = 0.0;
// 幾欄、幾列玻璃
uniform vec2 panes = vec2(3.0, 4.0);

float hash(float n) { return fract(sin(n * 91.7 + 3.1) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	float border = step(uv.x, 0.06) + step(0.94, uv.x) + step(uv.y, 0.045) + step(0.955, uv.y);
	vec2 cell = fract((uv - vec2(0.06, 0.045)) / vec2(0.88, 0.91) * panes);
	float bar = step(cell.x, 0.05) + step(0.95, cell.x) + step(cell.y, 0.04) + step(0.96, cell.y);
	float wood = clamp(border + bar, 0.0, 1.0);
	// 街對面的房子：一棟寬約半扇窗，屋簷高度、屋頂多尖每棟不一樣；有的有煙囪
	float gx = uv.x * 1.7 + seed * 2.3;
	float id = floor(gx);
	float fx = fract(gx);
	float eave = 0.6 + 0.16 * hash(id + seed);
	float peak = 0.1 + 0.12 * hash(id * 1.7 + 5.0);
	float roof = eave - peak * (1.0 - abs(fx - 0.5) * 2.0);
	float chimney = step(0.55, hash(id * 3.1 + 9.0)) * step(0.62, fx) * step(fx, 0.72) * step(roof - 0.09, uv.y);
	float house = max(step(roof, uv.y), chimney);
	// 房子上一兩扇小窗（只在背光的那一側看得出來：照到的那一側整片是逆光）
	vec2 wcell = vec2(fract(fx * 3.0), fract((uv.y - eave) * 9.0));
	float pane_lit = step(0.5, hash(id * 5.3 + floor(fx * 3.0) + floor((uv.y - eave) * 9.0) * 7.0));
	float house_window = house * step(eave + 0.03, uv.y) * step(0.35, wcell.x) * step(wcell.x, 0.65) * step(0.3, wcell.y) * step(wcell.y, 0.75) * pane_lit;
	// 天：上面亮、往下淡一點；每一格玻璃深淺差一點點
	vec2 pid = floor((uv - vec2(0.06, 0.045)) / vec2(0.88, 0.91) * panes);
	float glass = (0.72 + 0.28 * (1.0 - uv.y)) * (0.9 + 0.1 * fract(sin(dot(pid, vec2(12.9, 78.2))) * 43758.5));
	vec3 sky = light * energy * glass;
	vec3 houses = mix(house_color, light, 0.25) * (house_glow * energy + 0.25 * house_window);
	ALBEDO = mix(light * 0.25, frame_color, wood);
	EMISSION = mix(sky, houses, house) * (1.0 - wood);
	ROUGHNESS = mix(0.2, 0.9, wood);
}
