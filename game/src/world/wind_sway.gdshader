shader_type spatial;
// 會隨風晃的樹與灌木（ForestScenery.sway()）：顏色、法線、粗糙度照原本模型的貼圖（Tripo 匯出的 glTF），
// 頂點往風吹的方向擺——離地越高擺越多（sway_from 以下不動），整棵一起慢慢擺、樹梢再多一點細的抖；
// 每棵照自己的位置錯開，不會整片森林一起晃。tint＝這一棵的顏色偏移（每棵不一樣，看起來不像同一棵複製的）。

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D orm_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform bool has_normal = true;
uniform bool has_orm = true;
// 公尺（模型自己的座標，縮放之前）：這個高度以下不動、這個高度擺到 sway_amount
uniform float sway_from = 1.2;
uniform float sway_height = 6.5;
uniform float sway_amount = 0.16;
uniform float sway_speed = 0.7;
uniform vec2 wind_dir = vec2(0.8, -0.6);
instance uniform vec3 tint = vec3(1.0);
// 這個網格的原點離模型的原點多高（模型拆成好幾個節點時：灌木上一顆一顆的果子原點在果子中間，要照整棵的高度擺）
instance uniform float base_y = 0.0;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float h = clamp((VERTEX.y + base_y - sway_from) / max(sway_height - sway_from, 0.01), 0.0, 1.0);
	float phase = origin.x * 0.21 + origin.z * 0.17;
	float slow = sin(TIME * sway_speed + phase) * 0.7 + sin(TIME * sway_speed * 2.3 + phase * 1.7) * 0.3;
	float flutter = sin(TIME * 3.1 + dot(VERTEX, vec3(1.3, 0.7, 1.1)) * 2.0) * 0.12;
	vec2 push = normalize(wind_dir) * (slow + flutter) * sway_amount * h * h;
	vec3 world_push = vec3(push.x, -length(push) * 0.15, push.y);
	VERTEX += inverse(mat3(MODEL_MATRIX)) * world_push;
}

void fragment() {
	ALBEDO = texture(albedo_tex, UV).rgb * tint;
	if (has_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	if (has_orm) {
		vec4 orm = texture(orm_tex, UV);
		ROUGHNESS = orm.g;
		METALLIC = orm.b;
	} else {
		ROUGHNESS = 1.0;
		METALLIC = 0.0;
	}
}
