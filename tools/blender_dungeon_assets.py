"""
tools/blender_dungeon_assets.py
Authoritative 3D Dungeon & Combat Asset Pipeline for Relic Rush
Generates original modular geometry for:
1. Dungeon Modular Ironbound Door & Arch
2. Ancient Puzzle Runic Stele Pillar
3. Guardian Statue Golem Boss Model
Saves .blend files, exports .obj models, and renders 1080p visual evidence.
"""

import bpy
import math
import os
import sys
import mathutils

BASE_DIR = r"C:\RelicRushAI"
BLEND_DIR = os.path.join(BASE_DIR, "assets", "blender")
MODEL_DIR = os.path.join(BASE_DIR, "assets", "models")
EVIDENCE_DIR = os.path.join(BASE_DIR, "assets", "evidence")

for d in [BLEND_DIR, MODEL_DIR, EVIDENCE_DIR]:
    os.makedirs(d, exist_ok=True)

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES' if 'CYCLES' in bpy.context.preferences.addons else 'BLENDER_EEVEE_NEXT'
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 100

def direction_to_quaternion(direction):
    v = mathutils.Vector(direction).normalized()
    return v.to_track_quat('-Z', 'Y')

def setup_camera_and_lighting(cam_pos=(0, -12, 5), look_at=(0, 0, 2.5)):
    cam_data = bpy.data.cameras.new(name="RenderCam")
    cam_data.lens = 50
    cam_data.clip_start = 0.1
    cam_data.clip_end = 1000
    cam_obj = bpy.data.objects.new(name="RenderCam", object_data=cam_data)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    
    cam_obj.location = cam_pos
    direction = (look_at[0] - cam_pos[0], look_at[1] - cam_pos[1], look_at[2] - cam_pos[2])
    cam_obj.rotation_mode = 'QUATERNION'
    cam_obj.rotation_quaternion = direction_to_quaternion(direction)
    
    # Sunset Sunlight
    sun_data = bpy.data.lights.new(name="SunLight", type='SUN')
    sun_data.energy = 3.5
    sun_data.color = (1.0, 0.85, 0.70)
    sun_obj = bpy.data.objects.new(name="SunLight", object_data=sun_data)
    bpy.context.scene.collection.objects.link(sun_obj)
    sun_obj.rotation_mode = 'QUATERNION'
    sun_obj.rotation_quaternion = direction_to_quaternion((0.5, 0.8, -0.6))

    # Fill
    fill_data = bpy.data.lights.new(name="FillLight", type='SUN')
    fill_data.energy = 1.2
    fill_data.color = (0.35, 0.40, 0.60)
    fill_obj = bpy.data.objects.new(name="FillLight", object_data=fill_data)
    bpy.context.scene.collection.objects.link(fill_obj)
    fill_obj.rotation_mode = 'QUATERNION'
    fill_obj.rotation_quaternion = direction_to_quaternion((-0.5, -0.8, 0.6))

def create_material(name, color, roughness=0.4, metallic=0.0, emission_color=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
        if emission_color and emission_strength > 0:
            if "Emission Color" in bsdf.inputs:
                bsdf.inputs["Emission Color"].default_value = (*emission_color, 1.0)
                bsdf.inputs["Emission Strength"].default_value = emission_strength
            elif "Emission" in bsdf.inputs:
                bsdf.inputs["Emission"].default_value = (*emission_color, 1.0)
    return mat

def render_and_export(base_name, blend_path, obj_path, render_path):
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"[BlenderDungeon] Saved {blend_path}")

    try:
        bpy.ops.wm.obj_export(filepath=obj_path)
    except Exception:
        bpy.ops.export_scene.obj(filepath=obj_path)
    print(f"[BlenderDungeon] Exported {obj_path}")

    bpy.context.scene.render.filepath = render_path
    bpy.ops.render.render(write_still=True)
    print(f"[BlenderDungeon] Rendered {render_path}")

# ======================================================================
# 1. DUNGEON MODULAR IRONBOUND DOOR & ARCH
# ======================================================================
def build_dungeon_door():
    print("[BlenderDungeon] Generating Dungeon Modular Door...")
    reset_scene()
    setup_camera_and_lighting(cam_pos=(0, -18, 5.5), look_at=(0, 0, 4.0))

    mat_stone = create_material("CryptStone", (0.24, 0.24, 0.26), 0.7)
    mat_wood = create_material("AgedOak", (0.28, 0.18, 0.12), 0.8)
    mat_iron = create_material("DungeonIron", (0.18, 0.19, 0.22), 0.3, metallic=0.9)
    mat_ruby_rune = create_material("RubyRune", (0.95, 0.15, 0.25), 0.2, emission_color=(0.95, 0.15, 0.25), emission_strength=4.0)

    # Stone Jamb Pillars
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-4.5, 0, 4.5))
    pillar_l = bpy.context.active_object
    pillar_l.scale = (2.2, 2.8, 9.0)
    pillar_l.data.materials.append(mat_stone)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(4.5, 0, 4.5))
    pillar_r = bpy.context.active_object
    pillar_r.scale = (2.2, 2.8, 9.0)
    pillar_r.data.materials.append(mat_stone)

    # Pointed Stone Lintel Arch
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 9.5))
    lintel = bpy.context.active_object
    lintel.scale = (11.2, 3.2, 1.8)
    lintel.data.materials.append(mat_stone)

    # Carved Skull Keystone with Glowing Ruby Eyes
    bpy.ops.mesh.primitive_ico_sphere_add(radius=1.1, subdivisions=2, location=(0, 0.8, 9.5))
    keystone = bpy.context.active_object
    keystone.scale = (1.0, 0.8, 1.2)
    keystone.data.materials.append(mat_stone)

    for ex in [-0.35, 0.35]:
        bpy.ops.mesh.primitive_ico_sphere_add(radius=0.18, subdivisions=2, location=(ex, 1.6, 9.6))
        eye = bpy.context.active_object
        eye.data.materials.append(mat_ruby_rune)

    # Heavy Oak Double Doors
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 4.2))
    door = bpy.context.active_object
    door.scale = (6.8, 0.8, 8.4)
    door.data.materials.append(mat_wood)

    # Horizontal Iron Reinforcing Straps with Studs
    for z in [1.5, 4.2, 7.0]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.45, z))
        strap = bpy.context.active_object
        strap.scale = (7.0, 0.25, 0.6)
        strap.data.materials.append(mat_iron)

        for sx in [-2.5, -1.0, 1.0, 2.5]:
            bpy.ops.mesh.primitive_ico_sphere_add(radius=0.22, subdivisions=2, location=(sx, 0.6, z))
            stud = bpy.context.active_object
            stud.data.materials.append(mat_iron)

    # Giant Iron Ring Handle
    bpy.ops.mesh.primitive_torus_add(major_radius=0.6, minor_radius=0.14, location=(0.8, 0.7, 4.2), rotation=(math.pi/2, 0, 0))
    handle = bpy.context.active_object
    handle.data.materials.append(mat_iron)

    render_and_export(
        "dungeon_modular_door",
        os.path.join(BLEND_DIR, "dungeon_modular_door.blend"),
        os.path.join(MODEL_DIR, "dungeon_modular_door.obj"),
        os.path.join(EVIDENCE_DIR, "dungeon_modular_door_render.png")
    )

# ======================================================================
# 2. ANCIENT PUZZLE RUNIC STELE PILLAR
# ======================================================================
def build_puzzle_rune_pillar():
    print("[BlenderDungeon] Generating Puzzle Rune Pillar...")
    reset_scene()
    setup_camera_and_lighting(cam_pos=(0, -14, 5.0), look_at=(0, 0, 4.0))

    mat_granite = create_material("AgedGranite", (0.30, 0.28, 0.32), 0.6)
    mat_gold_trim = create_material("PuzzleGold", (0.92, 0.78, 0.22), 0.3, metallic=0.85)
    mat_cyan_rune = create_material("CyanRune", (0.20, 0.85, 1.0), 0.2, emission_color=(0.20, 0.85, 1.0), emission_strength=4.5)
    mat_green_rune = create_material("GreenRune", (0.25, 0.95, 0.40), 0.2, emission_color=(0.25, 0.95, 0.40), emission_strength=4.5)

    # Stepped Plinth
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.5))
    base1 = bpy.context.active_object
    base1.scale = (4.4, 4.4, 1.0)
    base1.data.materials.append(mat_granite)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.3))
    base2 = bpy.context.active_object
    base2.scale = (3.6, 3.6, 0.8)
    base2.data.materials.append(mat_gold_trim)

    # Tapered Obelisk Shaft
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=1.4, depth=7.0, location=(0, 0, 5.0))
    shaft = bpy.context.active_object
    shaft.data.materials.append(mat_granite)

    # 4 Rotating Puzzle Glyph Bands
    for i, z in enumerate([2.8, 4.2, 5.6, 7.0]):
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=1.55, depth=0.6, location=(0, 0, z))
        band = bpy.context.active_object
        band.data.materials.append(mat_gold_trim)

        # Inset glowing glyph gem
        mat_rune = mat_cyan_rune if (i % 2 == 0) else mat_green_rune
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 1.5, z))
        glyph = bpy.context.active_object
        glyph.scale = (0.5, 0.25, 0.4)
        glyph.data.materials.append(mat_rune)

    # Pyramidal Apex Cap with Floating Focus Crystal
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=1.4, radius2=0, depth=1.6, location=(0, 0, 9.2))
    cap = bpy.context.active_object
    cap.data.materials.append(mat_granite)

    bpy.ops.mesh.primitive_ico_sphere_add(radius=0.7, subdivisions=2, location=(0, 0, 10.6))
    crystal = bpy.context.active_object
    crystal.scale = (0.7, 0.7, 1.2)
    crystal.data.materials.append(mat_cyan_rune)

    render_and_export(
        "puzzle_rune_pillar",
        os.path.join(BLEND_DIR, "puzzle_rune_pillar.blend"),
        os.path.join(MODEL_DIR, "puzzle_rune_pillar.obj"),
        os.path.join(EVIDENCE_DIR, "puzzle_rune_pillar_render.png")
    )

# ======================================================================
# 3. GUARDIAN STATUE GOLEM BOSS MODEL
# ======================================================================
def build_guardian_golem():
    print("[BlenderDungeon] Generating Guardian Golem Boss...")
    reset_scene()
    setup_camera_and_lighting(cam_pos=(0, -20, 6.0), look_at=(0, 0, 4.5))

    mat_stone = create_material("GolemStone", (0.28, 0.28, 0.30), 0.7)
    mat_plate = create_material("GolemAplat", (0.18, 0.18, 0.20), 0.5, metallic=0.7)
    mat_core = create_material("GolemCore", (1.0, 0.35, 0.10), 0.2, emission_color=(1.0, 0.35, 0.10), emission_strength=5.0)
    mat_eye = create_material("GolemEye", (0.25, 0.95, 1.0), 0.2, emission_color=(0.25, 0.95, 1.0), emission_strength=5.0)

    # Massive Stone Pedestal
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.6))
    ped = bpy.context.active_object
    ped.scale = (6.0, 5.0, 1.2)
    ped.data.materials.append(mat_stone)

    # Pillar Legs
    for lx in [-1.8, 1.8]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(lx, 0, 2.5))
        leg = bpy.context.active_object
        leg.scale = (1.8, 2.2, 3.2)
        leg.data.materials.append(mat_plate)

    # Massive Armor Torso with Molten Heart Core
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 5.5))
    torso = bpy.context.active_object
    torso.scale = (4.8, 3.2, 4.0)
    torso.data.materials.append(mat_stone)

    # Molten Chest Core
    bpy.ops.mesh.primitive_ico_sphere_add(radius=1.1, subdivisions=2, location=(0, 1.4, 5.5))
    core = bpy.context.active_object
    core.data.materials.append(mat_core)

    # Broad Shoulders & Spiked Pauldrons
    for px in [-3.2, 3.2]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(px, 0, 6.8))
        pauld = bpy.context.active_object
        pauld.scale = (2.2, 2.8, 2.0)
        pauld.data.materials.append(mat_plate)

        # Spikes
        bpy.ops.mesh.primitive_cone_add(radius1=0.4, depth=1.4, location=(px, 0, 8.2))
        spike = bpy.context.active_object
        spike.data.materials.append(mat_plate)

    # Heavy Stone Arms & Claws
    for ax in [-3.6, 3.6]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(ax, 0.6, 4.0))
        arm = bpy.context.active_object
        arm.scale = (1.5, 1.8, 4.5)
        arm.data.materials.append(mat_stone)

    # Great Helm Head with Glowing Monocular Eye
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 8.2))
    head = bpy.context.active_object
    head.scale = (2.4, 2.4, 2.2)
    head.data.materials.append(mat_plate)

    bpy.ops.mesh.primitive_ico_sphere_add(radius=0.5, subdivisions=2, location=(0, 1.2, 8.2))
    eye = bpy.context.active_object
    eye.data.materials.append(mat_eye)

    render_and_export(
        "guardian_statue_golem",
        os.path.join(BLEND_DIR, "guardian_statue_golem.blend"),
        os.path.join(MODEL_DIR, "guardian_statue_golem.obj"),
        os.path.join(EVIDENCE_DIR, "guardian_statue_golem_render.png")
    )

if __name__ == "__main__":
    print("==================================================")
    print("  RELIC RUSH: 3D DUNGEON & GUARDIAN ASSET PIPELINE")
    print("==================================================")
    build_dungeon_door()
    build_puzzle_rune_pillar()
    build_guardian_golem()
    print("Dungeon & guardian 3D asset generation completed successfully!")
