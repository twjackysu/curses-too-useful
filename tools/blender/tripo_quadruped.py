"""把 Tripo 產的四足怪（art-inbox/tripo/<id>/<id>_anim.glb：有骨架、蒙皮、一段原地走路）轉成遊戲用的 glb。

Tripo 的四足模型塞在邊長 1 的方塊裡、頭朝 +X，旁邊還多一顆不相干的球。這裡只做三件事：
  把那顆球拿掉；整隻轉成頭朝 Godot 的 −Z、縮到 --length 公尺長（腳底在原點）；走路那一段改名叫 walk。
骨架、蒙皮、動作都原樣留著（遊戲裡用 AnimationPlayer 播 walk；撲咬之類的動作用程式擺）。
用法：python3 -I tools/blender/tripo_quadruped.py --src <anim.glb> --out <glb> --length 1.7
來源檔是外來的資料：只讀幾何、骨架與動作，不執行裡面的任何東西。
"""
import argparse
import math
import sys
from pathlib import Path

import bpy
import numpy as np


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--length", type=float, default=1.7, help="鼻尖到尾巴（公尺）")
    args = ap.parse_args()

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(args.src))
    arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and o.parent == arm]
    for o in list(bpy.context.scene.objects):
        if o is not arm and o not in meshes:
            bpy.data.objects.remove(o)
    # 量靜止姿勢下蒙皮之後的樣子（網格自己的座標是置中的，要經過骨架才是站在地上的那一隻）
    arm.data.pose_position = "REST"
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in meshes:
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        pts += [ev.matrix_world @ v.co for v in me.vertices]
        ev.to_mesh_clear()
    pts = np.array(pts, dtype=float)
    lo, hi = pts.min(0), pts.max(0)
    arm.data.pose_position = "POSE"
    scale = args.length / (hi[0] - lo[0])
    # 轉向、縮放、落地都放在外面多包的一層空物件上：骨架物件自己的位置與旋轉會被動作蓋掉（設了也沒用）。
    # Blender 的 +Y 匯出後是 Godot 的 −Z（前面）：頭從 +X 轉到 +Y
    holder = bpy.data.objects.new("Wolf", None)
    bpy.context.scene.collection.objects.link(holder)
    holder.rotation_mode = "XYZ"
    holder.rotation_euler = (0.0, 0.0, math.radians(90.0))
    holder.scale = (scale, scale, scale)
    holder.location = ((lo[1] + hi[1]) * 0.5 * scale, -(lo[0] + hi[0]) * 0.5 * scale, -lo[2] * scale)
    arm.parent = holder
    holder.select_set(True)
    for a in bpy.data.actions:
        a.name = "walk"
    arm.select_set(True)
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = arm
    args.out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(args.out), export_format="GLB", use_selection=True,
                              export_animations=True, export_yup=True, export_image_format="AUTO")
    tris = sum(len(p.vertices) - 2 for o in meshes for p in o.data.polygons)
    print(f"[{args.out.stem}] 已匯出（Tripo 四足）：{tris} 個三角面、長 {args.length:.2f}、高 {(hi[2] - lo[2]) * scale:.2f} m、"
          f"{len(bpy.data.actions)} 段動作、{args.out.stat().st_size // 1024} KB")


if __name__ == "__main__":
    sys.exit(main())
