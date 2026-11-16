shader_type spatial;
// 公會大廳的窗：一片貼在牆前面的面（背面不畫）。深色的木框＋十字窗櫺，一格一格的玻璃自己發光——
// 外面沒有做場景，天色就是玻璃的顏色（早上白裡帶暖、傍晚橘紅、背光的那一側暗藍）。`light`、`energy` 由 GuildScenery 設。

uniform vec3 light : source_color = vec3(1.0, 0.9, 0.7);
uniform float energy = 2.2;
uniform vec3 frame_color : source_color = vec3(0.2, 0.12, 0.08);
// 幾欄、幾列玻璃
uniform vec2 panes = vec2(3.0, 4.0);

void fragment() {
	vec2 uv = UV;
	float border = step(uv.x, 0.06) + step(0.94, uv.x) + step(uv.y, 0.045) + step(0.955, uv.y);
	vec2 cell = fract((uv - vec2(0.06, 0.045)) / vec2(0.88, 0.91) * panes);
	float bar = step(cell.x, 0.05) + step(0.95, cell.x) + step(cell.y, 0.04) + step(0.96, cell.y);
	float wood = clamp(border + bar, 0.0, 1.0);
	// 玻璃：上面亮、下面淡一點，每一格深淺差一點點
	vec2 id = floor((uv - vec2(0.06, 0.045)) / vec2(0.88, 0.91) * panes);
	float glass = (0.72 + 0.28 * (1.0 - uv.y)) * (0.9 + 0.1 * fract(sin(dot(id, vec2(12.9, 78.2))) * 43758.5));
	ALBEDO = mix(light * 0.25, frame_color, wood);
	EMISSION = light * energy * glass * (1.0 - wood);
	ROUGHNESS = mix(0.2, 0.9, wood);
}
