"""把 Tripo 產的角色（art-inbox/tripo/<id>/<id>_rig.glb，Mixamo 骨名、T 字站姿）轉成遊戲用的 glb（D-271）。

跟 vrm_character.py 一樣的出口：骨頭改成 Godot 人形骨架的名字、臉朝 Blender 的 +Y（匯出後＝Godot 的 −Z）、
腳底在原點、身高縮到指定的公尺數，再用 common.py 的 Animator 做 idle／walk／run／light_attack_01～03／release。
Tripo 自己附的動作（<id>_anim.glb）不用：只有 idle／walk／run，沒有出手與釋放，而且兩套動作混著用站姿會跳。

用法：python3 -I tools/blender/tripo_character.py --src art-inbox/tripo/sheila_rank_f/sheila_rank_f_rig.glb \
        --out build/art/characters/sheila/sheila.glb --name sheila --height 1.62
來源檔是外來的資料：只讀它的幾何、骨架與貼圖，不執行裡面的任何東西。
"""
import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import common as c  # noqa: E402

# Mixamo 的骨名（去掉 "mixamorig:"）→ Godot SkeletonProfileHumanoid
RENAME = {"Hips": "Hips", "Spine": "Spine", "Spine1": "Chest", "Spine2": "UpperChest", "Neck": "Neck", "Head": "Head"}
for _side in ("Left", "Right"):
    RENAME.update({_side + "Shoulder": _side + "Shoulder", _side + "Arm": _side + "UpperArm",
                   _side + "ForeArm": _side + "LowerArm", _side + "Hand": _side + "Hand",
                   _side + "UpLeg": _side + "UpperLeg", _side + "Leg": _side + "LowerLeg",
                   _side + "Foot": _side + "Foot", _side + "ToeBase": _side + "Toes"})
NEEDED = ("Hips", "Spine", "Chest", "Head", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm",
          "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg",
          "RightLowerLeg", "RightFoot")


# 休息姿勢的修正（2026-11-17，Jacky：「走路很怪、外八」）：Tripo 綁出來的 T 字站姿每個角色不一樣——
# 諾恩的腳尖往外 24°、兩腿張開 6～9°、大拇指朝上（手心朝前）；席菈幾乎是正的。common.py 的動作只會讓腿前後擺、
# 手臂往下放，原本的歪斜整段帶著走：走路外八、手心朝前像在討東西。所以先把休息姿勢扳正，再做動作。
# 改的是骨架的休息姿勢（網格跟著變形後重設），所以遊戲裡掛在手上的劍、手弩方向不變：掛點的方向是照
# 「手肘 → 手腕」與角色的前方算的（puppet.gd 的 _model_joint），跟手骨頭自己轉了幾度無關。
LEG_OUT_MAX = 4.0   # 腿往外張最多幾度（從骨盆到腳踝；原本比這小的不動）
TOE_OUT_MAX = 7.0   # 腳尖往外最多幾度（自然站姿的一點點外開；原本比這小的不動）
PALM_SPLIT = 0.5    # 手心轉向分給前臂幾成、其餘給手腕（全部放前臂，手肘的皮會扭成麻花）
PALM_MAX = 100.0    # 算出來要轉超過這麼多度，多半是大拇指的骨頭抓錯了（拳頭、爪子）：不轉


def straighten_rest(arm, meshes):
    bones = arm.data.bones
    up, fwd = Vector((0, 0, 1)), Vector((0, 1, 0))  # 上面已經把臉轉到 +Y
    hips = bones["Hips"].head_local
    turns = {}  # 骨頭 → 在骨架座標裡要轉的四元數（子骨頭會被父骨頭帶著走）
    notes = []
    for side in ("Left", "Right"):
        hip = bones[side + "UpperLeg"].head_local
        out = Vector((hip.x - hips.x, 0, 0)).normalized()  # 這一邊的「往外」
        leg = bones[side + "Foot"].head_local - hip
        o, f, z = leg.dot(out), leg.dot(fwd), leg.dot(up)
        spread = math.degrees(math.atan2(o, -z))
        if spread > LEG_OUT_MAX:
            o = -z * math.tan(math.radians(LEG_OUT_MAX))
        target = (out * o + fwd * f + up * z).normalized()
        toes_name = side + "Toes"
        rot = leg.normalized().rotation_difference(target)
        yaw = 0.0
        if toes_name in bones:
            foot = bones[toes_name].head_local - bones[side + "Foot"].head_local
            yaw = math.degrees(math.atan2(foot.dot(out), foot.dot(fwd)))
            want = min(yaw, TOE_OUT_MAX)
            toe = (fwd * math.cos(math.radians(want)) + out * math.sin(math.radians(want)))

            def frame(axis, hint):
                h = Vector((hint.x, hint.y, 0)) - axis * Vector((hint.x, hint.y, 0)).dot(axis)
                h.normalize()
                return Matrix((axis, h, axis.cross(h))).transposed()

            m = frame(target, toe) @ frame(leg.normalized(), foot).inverted()
            rot = m.to_quaternion()
        turns[side + "UpperLeg"] = rot
        notes.append(f"{side} 腿張 {spread:.0f}°、腳尖外 {yaw:.0f}°")

        elbow, wrist = bones[side + "LowerArm"].head_local, bones[side + "Hand"].head_local
        axis = (wrist - elbow).normalized()
        thumb = next((b for b in bones if b.name.split(":")[-1] == side + "HandThumb1"), None)
        if thumb is None:
            continue
        u = thumb.head_local - wrist
        u = (u - axis * u.dot(axis)).normalized()
        f2 = (fwd - axis * fwd.dot(axis)).normalized()
        roll = math.atan2(axis.dot(u.cross(f2)), u.dot(f2))  # 把大拇指轉到朝前（手放下來手心就朝大腿）
        if abs(math.degrees(roll)) > PALM_MAX:
            notes.append(f"{side} 手心要轉 {math.degrees(roll):.0f}° 太多、不轉")
            continue
        turns[side + "LowerArm"] = Quaternion(axis, roll * PALM_SPLIT)
        turns[side + "Hand"] = Quaternion(axis, roll * (1.0 - PALM_SPLIT))
        notes.append(f"{side} 手心轉 {math.degrees(roll):.0f}°")
    for name, q in turns.items():
        pb = arm.pose.bones[name]
        r = bones[name].matrix_local.to_3x3().to_quaternion()
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = r.inverted() @ q @ r
    bpy.context.view_layer.update()
    for o in meshes:
        mod = next(m for m in o.modifiers if m.type == "ARMATURE")
        name = mod.name
        if o.data.shape_keys is not None:
            o.shape_key_clear()
        with bpy.context.temp_override(object=o, active_object=o, selected_objects=[o]):
            bpy.ops.object.modifier_apply(modifier=name)
        o.modifiers.new(name, "ARMATURE").object = arm
    with bpy.context.temp_override(object=arm, active_object=arm, selected_objects=[arm]):
        bpy.ops.object.mode_set(mode="POSE")
        bpy.ops.pose.armature_apply(selected=False)
        bpy.ops.object.mode_set(mode="OBJECT")
    print("[tripo] 休息姿勢扳正：" + "、".join(notes))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--name", default="character")
    ap.add_argument("--height", type=float, default=1.65, help="腳底到頭頂（公尺）")
    ap.add_argument("--keep-rest", action="store_true",
                    help="不扳正休息姿勢（怪物：張開的腿、外八、握拳是設計，扳正反而怪）")
    args = ap.parse_args()

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(args.src))
    arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
    meshes = [o for o in bpy.context.scene.objects
              if o.type == "MESH" and any(m.type == "ARMATURE" for m in o.modifiers)]
    for o in list(bpy.context.scene.objects):  # 沒綁骨架的網格（骨頭的顯示用形狀）、空物件
        if o is not arm and o not in meshes:
            bpy.data.objects.remove(o)
    if arm.animation_data is not None:
        arm.animation_data_clear()
    for act in list(bpy.data.actions):
        bpy.data.actions.remove(act)
    arm.name = args.name.capitalize()
    for bone in arm.data.bones:
        short = bone.name.split(":")[-1]
        if short in RENAME:
            bone.name = RENAME[short]  # 頂點群組跟著改名
    missing = [b for b in NEEDED if b not in arm.data.bones]
    if missing:
        raise SystemExit(f"[tripo] 缺骨頭：{missing}")

    # 朝向、比例、原點：直接改網格與骨架的資料（不靠物件的變形，匯出後根節點是乾淨的）
    def world_head(bone):
        return arm.matrix_world @ arm.data.bones[bone].head_local

    left = world_head("LeftUpperArm") - world_head("RightUpperArm")
    forward = Vector((left.x, left.y, 0.0)).cross(Vector((0, 0, 1)))  # 左 × 上＝前
    turn = Matrix.Rotation(math.atan2(forward.x, forward.y), 4, "Z")  # 把「前」轉到 +Y
    pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    z_lo, z_hi = min(p.z for p in pts), max(p.z for p in pts)
    hips = world_head("Hips")
    scale = args.height / (z_hi - z_lo)
    fix = Matrix.Scale(scale, 4) @ turn @ Matrix.Translation((-hips.x, -hips.y, -z_lo))
    for o in meshes:
        o.data.transform(fix @ o.matrix_world)
        o.parent = arm
        o.matrix_parent_inverse = Matrix.Identity(4)
        o.matrix_basis = Matrix.Identity(4)
    arm.data.transform(fix @ arm.matrix_world)
    arm.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()

    if not args.keep_rest:
        straighten_rest(arm, meshes)

    def head(bone):
        return arm.matrix_world @ arm.data.bones[bone].head_local

    face =(head("LeftUpperArm") - head("RightUpperArm")).cross(Vector((0, 0, 1))).normalized()
    segs = {}
    for side in ("Left", "Right"):
        segs[side + "UpperArm"] = (head(side + "UpperArm"), head(side + "LowerArm"))
        segs[side + "LowerArm"] = (head(side + "LowerArm"), head(side + "Hand"))
    tris = sum(len(p.vertices) - 2 for o in meshes for p in o.data.polygons)
    print(f"[tripo] {len(meshes)} 個網格、{tris} 個三角面、{len(arm.data.bones)} 根骨頭、"
          f"原本高 {z_hi - z_lo:.2f} → {args.height:.2f} m、臉朝 ({face.x:+.2f}, {face.y:+.2f})（要 +Y）、"
          f"骨盆高 {head('Hips').z:.2f}、頭的骨頭高 {head('Head').z:.2f}")

    a = c.Animator(arm, segs)
    c.standard_actions(a)
    c.release_action(a)
    c.activate(meshes[0])
    for o in meshes:
        o.select_set(True)
    arm.select_set(True)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(args.out), export_format="GLB", use_selection=True,
                              export_animations=True, export_animation_mode="NLA_TRACKS", export_skins=True,
                              export_yup=True, export_image_format="AUTO", export_force_sampling=True)
    c.patch_orm(args.out)
    print(f"[{args.name}] 已匯出 {args.out.name}（Tripo）：{tris} 個三角面、身高 {args.height:.2f} m、"
          f"{args.out.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
