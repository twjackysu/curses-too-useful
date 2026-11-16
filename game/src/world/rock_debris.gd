class_name RockDebris
extends RefCounted
## 飛出去的碎塊：不透明的小石塊，往 dir 那一側噴、邊飛邊轉、往下掉、越來越小。
## 魔像被砍掉的石屑、粉碎的核心（glow 大於 0＝自己會亮的晶片：細長的三角碎片）、石化解除時剝落的殼都是它。
## 石塊是面數很少的扁球（看起來是有稜角的石頭）；不用方塊——飛到鏡頭前面一眼就看得出是盒子。
## 掛在 parent 底下（通常是關卡：倒下沉進地面的敵人不會把它帶走），噴完自己收掉。

const LIFE_SEC: float = 0.9


## at＝世界座標；speed＝初速的最小與最大（m/s）；size＝石塊的長邊（m）。回傳那一團（測試數得到）。
static func burst(parent: Node, at: Vector3, dir: Vector3, amount: int, size: float, color: Color,
		speed: Vector2, glow: float = 0.0) -> CPUParticles3D:
	var ps := CPUParticles3D.new()
	ps.name = "RockDebris"
	ps.emitting = false
	ps.one_shot = true
	ps.explosiveness = 1.0
	ps.amount = amount
	ps.lifetime = LIFE_SEC
	ps.randomness = 0.4
	ps.direction = dir.normalized() if dir.length() > 0.01 else Vector3.UP
	ps.spread = 55.0
	ps.initial_velocity_min = speed.x
	ps.initial_velocity_max = speed.y
	ps.gravity = Vector3(0, -14.0, 0)
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	ps.emission_sphere_radius = size * 1.5
	ps.angle_min = 0.0
	ps.angle_max = 360.0
	ps.angular_velocity_min = -540.0
	ps.angular_velocity_max = 540.0
	ps.scale_amount_min = 0.5
	ps.scale_amount_max = 1.3
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(0.7, 0.9))
	shrink.add_point(Vector2(1.0, 0.0))
	ps.scale_amount_curve = shrink
	var chunk: PrimitiveMesh
	if glow > 0.0:
		var shard := PrismMesh.new()
		shard.size = Vector3(size * 0.5, size * 1.5, size * 0.22)
		chunk = shard
	else:
		var rock := SphereMesh.new()
		rock.radius = size * 0.5
		rock.height = size * 0.7
		rock.radial_segments = 5
		rock.rings = 2
		chunk = rock
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	chunk.material = mat
	ps.mesh = chunk
	ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# 先擺好位置才開始噴（一次全部噴出來的粒子，進場景樹的那一刻在哪就噴在哪）
	parent.add_child(ps, true)
	ps.global_position = at
	ps.emitting = true
	ps.finished.connect(ps.queue_free)
	return ps
