shader_type spatial;
// 賒帳街的屋頂（TownScenery 的 PrismMesh）：一排一排的瓦，每一片下緣有一道陰影、深淺不一，屋脊一道深色的脊瓦。
// 兩片斜面用瓦、兩頭的山牆（PrismMesh 的三角形那兩面，朝本地 ±Z）畫成灰泥＋木框。位置照屋頂自己的座標算（屋脊順著本地 Z）。

uniform vec3 tile : source_color = vec3(0.62, 0.26, 0.2);
uniform vec3 plaster : source_color = vec3(0.92, 0.85, 0.72);
uniform vec3 timber : source_color = vec3(0.32, 0.2, 0.13);
uniform vec3 size = vec3(8.0, 2.0, 6.0);
uniform float seed = 0.0;

varying vec3 local_pos;
varying vec3 local_n;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void vertex() {
	local_pos = VERTEX;
	local_n = NORMAL;
}

void fragment() {
	float y = local_pos.y + size.y * 0.5;
	if (abs(local_n.z) > 0.8) {
		// 山牆：灰泥，邊上一圈木框
		float edge = min(y, abs(abs(local_pos.x) - (size.x * 0.5) * (1.0 - y / size.y)));
		vec3 col = plaster * 0.86;
		col = mix(col, timber, 1.0 - smoothstep(0.14, 0.17, edge));
		ALBEDO = col;
		ROUGHNESS = 0.9;
	} else {
		// 沿著斜面往下算幾排（從屋脊往屋簷）
		float down = size.y - y;
		float row = floor(down / 0.32);
		float x = local_pos.z / 0.36 + 0.5 * mod(row, 2.0);
		float f = fract(down / 0.32);
		float tone = hash(vec2(floor(x), row + seed));
		vec3 col = tile * (0.78 + 0.32 * tone);
		col *= mix(1.0, 0.55, smoothstep(0.72, 1.0, f));
		col *= 0.92 + 0.08 * smoothstep(0.0, 0.1, abs(fract(x) - 0.5));
		col = mix(col, tile * 0.42, 1.0 - smoothstep(0.12, 0.16, down));
		ALBEDO = col;
		ROUGHNESS = 0.75;
		SPECULAR = 0.25;
	}
}
