shader_type spatial;
// 腐敗之森的地面：一大片平面（外圍照高度圖往上推成土坡：ForestMap.height_mask()，只是看的、碰撞還是平的），顏色照世界座標用雜訊混——暗土、苔、發紫的腐葉，路與空地是比較亮的土，毒沼是濕的黑泥，
// 邊緣是不規則的（不是一條直線），近處灑一些落葉。全部用算的，沒有貼圖。
// moss 跟 tools/blender/tripo_prop.py 的 MOSS 同一個顏色：樹的模型自帶的土丘改塗成它，才會跟地面接起來。

uniform vec3 soil : source_color = vec3(0.15, 0.12, 0.18);
uniform vec3 moss : source_color = vec3(0.12, 0.22, 0.18);
uniform vec3 rot : source_color = vec3(0.25, 0.15, 0.31);
uniform vec3 dirt : source_color = vec3(0.37, 0.3, 0.3);
// 路、空地與毒沼：關卡把地圖畫成一張小圖（ForestMap.trail_mask()：R＝土路與空地，邊界是 0.5；G＝毒沼），這裡用雜訊把邊緣咬成不規則的
uniform sampler2D trail_mask : hint_default_black, filter_linear, repeat_disable;
uniform vec3 bog : source_color = vec3(0.07, 0.1, 0.1);
uniform vec3 bog_glow : source_color = vec3(0.16, 0.42, 0.2);
// 樹腳下長苔：關卡把每棵樹的位置畫成一張小圖（R＝離樹多近），這裡照它把地面換成苔
uniform sampler2D moss_mask : hint_default_black, filter_linear, repeat_disable;
uniform float ground_size = 140.0;
// 高度圖（R＝公尺）：路網附近是 0，走不到的外圍隆起
uniform sampler2D height_map : hint_default_black, filter_linear, repeat_disable;

varying vec3 world_pos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv = world_pos.xz / ground_size + 0.5;
	float h = texture(height_map, uv).r;
	// 法線照旁邊四點的高度差算（坡面才吃得到月光的明暗）
	float texel = 1.0 / float(textureSize(height_map, 0).x);
	float dx = texture(height_map, uv + vec2(texel, 0.0)).r - texture(height_map, uv - vec2(texel, 0.0)).r;
	float dz = texture(height_map, uv + vec2(0.0, texel)).r - texture(height_map, uv - vec2(0.0, texel)).r;
	float span = 2.0 * texel * ground_size;
	VERTEX.y += h;
	NORMAL = normalize(vec3(-dx / span, 1.0, -dz / span));
	world_pos.y += h;
}

void fragment() {
	vec2 p = world_pos.xz;
	float patches = fbm(p * 0.16);
	float grain = fbm(p * 1.3 + 31.0);
	float near_tree = texture(moss_mask, p / ground_size + 0.5).r;
	float mossy = max(smoothstep(0.36, 0.48, patches), smoothstep(0.3, 0.55, near_tree + (patches - 0.45) * 0.8));
	vec3 col = mix(soil, moss, mossy);
	col = mix(col, rot, smoothstep(0.58, 0.7, fbm(p * 0.1 + 43.0)) * 0.7 * (1.0 - near_tree));
	// 路與空地：邊緣跟著雜訊走
	vec2 trail = texture(trail_mask, p / ground_size + 0.5).rg;
	float wobble = fbm(p * 0.3 + 7.0) - 0.5;
	float bare = smoothstep(0.42, 0.58, trail.r + wobble * 0.45);
	float wet = smoothstep(0.4, 0.62, trail.g + wobble * 0.5);
	col = mix(col, dirt, bare * (0.75 + 0.25 * grain));
	col *= 0.78 + 0.44 * grain;
	// 落葉：每格一片，位置、大小、顏色照格子的亂數；路上少一點；遠處不畫（會閃）
	float near = 1.0 - smoothstep(14.0, 26.0, length(VERTEX));
	vec2 cell = floor(p * 2.4);
	vec2 in_cell = fract(p * 2.4) - 0.5;
	float pick = hash(cell + 3.7);
	vec2 offset = (vec2(hash(cell + 9.1), hash(cell + 21.3)) - 0.5) * 0.6;
	float turn = pick * 6.283;
	vec2 q = mat2(vec2(cos(turn), -sin(turn)), vec2(sin(turn), cos(turn))) * (in_cell - offset);
	float leaf = 1.0 - smoothstep(0.6, 1.0, length(q * vec2(5.0, 11.0)));
	leaf *= step(mix(0.62, 0.86, bare), pick) * near;
	vec3 leaf_col = mix(vec3(0.42, 0.27, 0.12), vec3(0.36, 0.17, 0.42), step(0.5, hash(cell + 55.5)));
	col = mix(col, leaf_col, leaf * 0.85);
	// 毒沼：整片是濕的黑泥，一灘一灘發綠的水（月光照得出反光）
	float pools = smoothstep(0.5, 0.62, fbm(p * 0.45 + 91.0)) * wet;
	col = mix(col, bog * (0.7 + 0.5 * grain), wet * 0.9);
	col = mix(col, bog_glow, pools * 0.55);
	ALBEDO = col;
	ROUGHNESS = mix(1.0, 0.25, max(pools, wet * 0.35));
	SPECULAR = mix(0.1, 0.6, pools);
	EMISSION = bog_glow * pools * 0.25;
}
