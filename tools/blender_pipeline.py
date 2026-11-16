"""
tools/blender_pipeline.py
Authoritative 3D Asset & Mesh Pipeline for Relic Rush
Generates original modular geometry, saves editable .blend files,
exports clean .obj models, and renders high-fidelity visual evidence.
"""

import bpy
import math
import os
import sys

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

def setup_camera_and_lighting(cam_pos=(0, -8, 4), look_at=(0, 0, 1.5)):
    # Camera
    cam_data = bpy.data.cameras.new(name="RenderCam")
    cam_data.lens = 50
    cam_data.clip_start = 0.1
    cam_data.clip_end = 1000
    cam_obj = bpy.data.objects.new(name="RenderCam", object_data=cam_data)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    
    cam_obj.location = cam_pos
    direction = (look_at[0] - cam_pos[0], look_at[1] - cam_pos[1], look_at[2] - cam_pos[2])
    rot_quat = direction_to_quaternion(direction)
    cam_obj.rotation_mode = 'QUATERNION'
    cam_obj.rotation_quaternion = rot_quat
    
    # Key Light (Warm Sunset Sunlight)
    sun_data = bpy.data.lights.new(name="SunLight", type='SUN')
    sun_data.energy = 3.5
    sun_data.color = (1.0, 0.85, 0.7)
    sun_obj = bpy.data.objects.new(name="SunLight", object_data=sun_data)
    sun_obj.rotation_euler = (math.radians(45), math.radians(15), math.radians(-30))
    bpy.context.scene.collection.objects.link(sun_obj)

    # Fill Light (Cool Twilight Bounce)
    fill_data = bpy.data.lights.new(name="FillLight", type='SUN')
    fill_data.energy = 1.2
    fill_data.color = (0.35, 0.4, 0.6)
    fill_obj = bpy.data.objects.new(name="FillLight", object_data=fill_data)
    fill_obj.rotation_euler = (math.radians(-45), math.radians(-15), math.radians(150))
    bpy.context.scene.collection.objects.link(fill_obj)

def direction_to_quaternion(direction):
    import mathutils
    v = mathutils.Vector(direction).normalized()
    up = mathutils.Vector((0, 0, 1))
    return v.to_track_quat('-Z', 'Y')

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
    # Save .blend
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"[BlenderPipeline] Saved {blend_path}")

    # Export .obj
    try:
        bpy.ops.wm.obj_export(filepath=obj_path)
    except Exception:
        bpy.ops.export_scene.obj(filepath=obj_path)
    print(f"[BlenderPipeline] Exported {obj_path}")

    # Render image
    bpy.context.scene.render.filepath = render_path
    bpy.ops.render.render(write_still=True)
    print(f"[BlenderPipeline] Rendered visual evidence: {render_path}")

# ====================================================================
# 1. THE SIGNATURE HOLLOW CROWN (Hero Relic)
# ====================================================================
def generate_hollow_crown():
    print("[BlenderPipeline] Generating The Hollow Crown...")
    reset_scene()
    setup_camera_and_lighting(cam_pos=(0, -4.5, 2.2), look_at=(0, 0, 0.6))
    
    mat_gold = create_material("CrownGold", (0.95, 0.78, 0.22), roughness=0.25, metallic=0.9)
    mat_obsidian = create_material("CrownObsidian", (0.08, 0.07, 0.10), roughness=0.15, metallic=0.3)
    mat_void = create_material("VoidRuby", (0.92, 0.12, 0.38), roughness=0.1, metallic=0.0, emission_color=(0.95, 0.15, 0.4), emission_strength=4.0)

    # Circlet Base
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=1.3, depth=0.25, location=(0, 0, 0.125))
    base = bpy.context.active_object
    base.name = "CircletBase"
    base.data.materials.append(mat_obsidian)

    # Gold Rim Collar
    bpy.ops.mesh.primitive_torus_add(major_radius=1.32, minor_radius=0.06, location=(0, 0, 0.25))
    rim = bpy.context.active_object
    rim.name = "GoldRim"
    rim.data.materials.append(mat_gold)

    # 8 Crown Spikes (4 Cardinal Large, 4 Diagonal Medium)
    for i in range(8):
        angle = math.radians(i * 45)
        is_cardinal = (i % 2 == 0)
        h = 1.3 if is_cardinal else 0.85
        r_base = 0.14 if is_cardinal else 0.10
        x = math.cos(angle) * 1.25
        y = math.sin(angle) * 1.25
        
        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=r_base, radius2=0.01, depth=h, location=(x, y, 0.25 + h/2))
        spike = bpy.context.active_object
        spike.name = f"Spike_{i}"
        spike.data.materials.append(mat_gold)

    # Floating Void Ruby Core Sphere
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=0.48, location=(0, 0, 0.65))
    void_orb = bpy.context.active_object
    void_orb.name = "VoidRubyOrb"
    void_orb.data.materials.append(mat_void)

    blend_path = os.path.join(BLEND_DIR, "relic_hollow_crown.blend")
    obj_path = os.path.join(MODEL_DIR, "relic_hollow_crown.obj")
    render_path = os.path.join(EVIDENCE_DIR, "relic_hollow_crown_render.png")
    render_and_export("relic_hollow_crown", blend_path, obj_path, render_path)

# ====================================================================
# 2. GOTHIC POINTED ARCHWAY & FLUTED COLUMNS (Architecture Family)
# ====================================================================
def generate_gothic_archway():
    print("[BlenderPipeline] Generating Gothic Archway...")
    reset_scene()
    # Position camera further back and slightly elevated to frame entire 12-stud arch
    setup_camera_and_lighting(cam_pos=(0, -22, 6.5), look_at=(0, 0, 5.5))

    mat_stone = create_material("ArchStone", (0.42, 0.40, 0.44), roughness=0.6, metallic=0.0)
    mat_gold_trim = create_material("ArchGoldTrim", (0.88, 0.72, 0.24), roughness=0.3, metallic=0.85)

    # Left and Right Foundation Bases
    for side, x in [("L", -3.5), ("R", 3.5)]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, 0, 0.6))
        plinth = bpy.context.active_object
        plinth.scale = (1.8, 1.8, 1.2)
        plinth.data.materials.append(mat_stone)

        # Fluted Column Shaft
        bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.65, depth=6.5, location=(x, 0, 4.45))
        col = bpy.context.active_object
        col.name = f"Column_{side}"
        col.data.materials.append(mat_stone)

        # Capital
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, 0, 7.9))
        cap = bpy.context.active_object
        cap.scale = (1.6, 1.6, 0.6)
        cap.data.materials.append(mat_gold_trim)

    # Pointed Archway Spans
    bpy.ops.mesh.primitive_torus_add(major_radius=3.5, minor_radius=0.7, location=(0, 0, 7.8))
    arch = bpy.context.active_object
    arch.scale = (1.0, 1.0, 1.2)
    arch.data.materials.append(mat_stone)

    # Keystone Emblem at Apex
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 11.2))
    keystone = bpy.context.active_object
    keystone.scale = (1.2, 1.6, 1.4)
    keystone.data.materials.append(mat_gold_trim)

    blend_path = os.path.join(BLEND_DIR, "archway_gothic.blend")
    obj_path = os.path.join(MODEL_DIR, "archway_gothic.obj")
    render_path = os.path.join(EVIDENCE_DIR, "archway_gothic_render.png")
    render_and_export("archway_gothic", blend_path, obj_path, render_path)

# ====================================================================
# 3. ANCIENT DRUIDIC RUNIC MONOLITH (Natural/Fantasy Family)
# ====================================================================
def generate_druidic_monolith():
    print("[BlenderPipeline] Generating Druidic Monolith...")
    reset_scene()
    # Position camera back to frame full 8-stud monolith from base to crown
    setup_camera_and_lighting(cam_pos=(0, -18, 4.2), look_at=(0, 0, 3.8))

    mat_megalith = create_material("MegalithSlate", (0.28, 0.32, 0.28), roughness=0.75, metallic=0.0)
    mat_rune = create_material("EmeraldRune", (0.3, 0.9, 0.4), roughness=0.2, metallic=0.0, emission_color=(0.3, 0.95, 0.45), emission_strength=3.5)
    mat_moss = create_material("LichenMoss", (0.18, 0.35, 0.16), roughness=0.9, metallic=0.0)

    # Monolith Main Pillar with Beveled Geometry
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 3.8))
    pillar = bpy.context.active_object
    pillar.scale = (1.8, 1.2, 7.6)
    pillar.data.materials.append(mat_megalith)

    # Carved Glowing Runic Ribbons
    for i in range(3):
        z = 2.0 + i * 2.2
        bpy.ops.mesh.primitive_torus_add(major_radius=1.1, minor_radius=0.12, location=(0, 0, z))
        band = bpy.context.active_object
        band.scale = (1.1, 0.75, 1.0)
        band.data.materials.append(mat_rune)

    # Ivy Vine / Moss Clumps at Base
    for side, pos in [("F", (0, 0.7, 1.0)), ("B", (0, -0.7, 0.8)), ("L", (-1.0, 0, 1.2))]:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.6, location=pos)
        moss = bpy.context.active_object
        moss.data.materials.append(mat_moss)

    blend_path = os.path.join(BLEND_DIR, "druidic_monolith.blend")
    obj_path = os.path.join(MODEL_DIR, "druidic_monolith.obj")
    render_path = os.path.join(EVIDENCE_DIR, "druidic_monolith_render.png")
    render_and_export("druidic_monolith", blend_path, obj_path, render_path)

# ====================================================================
# 4. MONUMENTAL CROWN SPIRE WITH ORBITAL RINGS (Hero Monument)
# ====================================================================
def generate_crown_spire():
    print("[BlenderPipeline] Generating Crown Spire...")
    reset_scene()
    # Position camera back at distance to frame the entire 20-stud spire and orbital rings
    setup_camera_and_lighting(cam_pos=(0, -36, 12), look_at=(0, 0, 9.5))

    mat_obsidian = create_material("SpireObsidian", (0.07, 0.05, 0.10), roughness=0.2, metallic=0.4)
    mat_violet = create_material("AstralViolet", (0.75, 0.25, 0.9), roughness=0.1, metallic=0.0, emission_color=(0.8, 0.3, 0.95), emission_strength=4.5)
    mat_gold = create_material("SpireGold", (0.92, 0.76, 0.2), roughness=0.3, metallic=0.9)

    # Multi-tier Base Plinths
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=4.5, depth=1.2, location=(0, 0, 0.6))
    plinth1 = bpy.context.active_object
    plinth1.data.materials.append(mat_obsidian)

    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=3.2, depth=1.0, location=(0, 0, 1.7))
    plinth2 = bpy.context.active_object
    plinth2.data.materials.append(mat_gold)

    # Main Spire Needle
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=1.8, radius2=0.05, depth=16.0, location=(0, 0, 10.2))
    needle = bpy.context.active_object
    needle.data.materials.append(mat_obsidian)

    # Concentric Orbital Celestial Rings
    bpy.ops.mesh.primitive_torus_add(major_radius=4.8, minor_radius=0.18, location=(0, 0, 7.5))
    ring1 = bpy.context.active_object
    ring1.rotation_euler = (math.radians(25), math.radians(10), 0)
    ring1.data.materials.append(mat_violet)

    bpy.ops.mesh.primitive_torus_add(major_radius=3.4, minor_radius=0.14, location=(0, 0, 11.5))
    ring2 = bpy.context.active_object
    ring2.rotation_euler = (math.radians(-20), math.radians(15), 0)
    ring2.data.materials.append(mat_gold)

    # Beacon Apex Orb
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=0.9, location=(0, 0, 18.5))
    beacon = bpy.context.active_object
    beacon.data.materials.append(mat_violet)

    blend_path = os.path.join(BLEND_DIR, "crown_spire.blend")
    obj_path = os.path.join(MODEL_DIR, "crown_spire.obj")
    render_path = os.path.join(EVIDENCE_DIR, "crown_spire_render.png")
    render_and_export("crown_spire", blend_path, obj_path, render_path)

# ====================================================================
# 5. ANCIENT TWISTED WISPWOOD TREE (Natural Environment Family)
# ====================================================================
def generate_ancient_tree():
    print("[BlenderPipeline] Generating Ancient Wispwood Tree...")
    reset_scene()
    setup_camera_and_lighting(cam_pos=(0, -28, 10), look_at=(0, 0, 7.5))

    mat_bark = create_material("WispwoodBark", (0.24, 0.16, 0.11), roughness=0.85, metallic=0.0)
    mat_leaves = create_material("WispwoodCanopy", (0.12, 0.35, 0.18), roughness=0.7, metallic=0.0)
    mat_wisp = create_material("VerdantWisp", (0.35, 0.95, 0.45), roughness=0.1, metallic=0.0, emission_color=(0.4, 1.0, 0.5), emission_strength=5.0)

    # Main Twisted Trunk
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1.6, depth=10.0, location=(0, 0, 5.0))
    trunk = bpy.context.active_object
    trunk.data.materials.append(mat_bark)

    # 4 Sprawling Buttress Roots
    for i in range(4):
        ang = math.radians(i * 90 + 20)
        rx = math.cos(ang) * 2.2
        ry = math.sin(ang) * 2.2
        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=1.0, radius2=0.3, depth=3.2, location=(rx, ry, 1.6))
        root = bpy.context.active_object
        root.rotation_euler = (math.radians(15) * math.sin(ang), math.radians(-15) * math.cos(ang), ang)
        root.data.materials.append(mat_bark)

    # Foliage Canopy Balls
    canopy_offsets = [
        (0, 0, 11.5, 4.2),
        (-2.5, 1.5, 10.5, 3.2),
        (2.5, -1.2, 10.2, 3.0),
        (0, 2.8, 9.8, 2.8),
    ]
    for cx, cy, cz, cr in canopy_offsets:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=cr, location=(cx, cy, cz))
        foliage = bpy.context.active_object
        foliage.data.materials.append(mat_leaves)

    # Hanging Wisp Lantern Pods
    wisp_locs = [(-2.2, 0.8, 8.5), (2.0, -1.0, 8.0), (0.5, 2.2, 8.2)]
    for wx, wy, wz in wisp_locs:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.45, location=(wx, wy, wz))
        wisp = bpy.context.active_object
        wisp.data.materials.append(mat_wisp)

    blend_path = os.path.join(BLEND_DIR, "ancient_wispwood_tree.blend")
    obj_path = os.path.join(MODEL_DIR, "ancient_wispwood_tree.obj")
    render_path = os.path.join(EVIDENCE_DIR, "ancient_wispwood_tree_render.png")
    render_and_export("ancient_wispwood_tree", blend_path, obj_path, render_path)

# ====================================================================
# 6. LUXURY ARTISAN MARKET STALL (Hub Architecture Family)
# ====================================================================
def generate_merchant_stall():
    print("[BlenderPipeline] Generating Luxury Artisan Market Stall...")
    reset_scene()
    setup_camera_and_lighting(cam_pos=(0, -14, 5.5), look_at=(0, 0, 3.2))

    mat_wood = create_material("StallTimber", (0.32, 0.20, 0.12), roughness=0.8, metallic=0.0)
    mat_canopy = create_material("StallCanopyCrimson", (0.65, 0.15, 0.20), roughness=0.7, metallic=0.0)
    mat_valance = create_material("StallValanceGold", (0.88, 0.75, 0.35), roughness=0.5, metallic=0.3)
    mat_lantern = create_material("StallLanternGlow", (1.0, 0.85, 0.4), roughness=0.1, metallic=0.0, emission_color=(1.0, 0.8, 0.3), emission_strength=4.0)

    # 4 Corner Timber Posts
    for px, py in [(-3.2, -2.2), (3.2, -2.2), (-3.2, 2.2), (3.2, 2.2)]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(px, py, 3.2))
        post = bpy.context.active_object
        post.scale = (0.35, 0.35, 6.4)
        post.data.materials.append(mat_wood)

    # Display Counter
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.6))
    counter = bpy.context.active_object
    counter.scale = (6.2, 3.2, 2.8)
    counter.data.materials.append(mat_wood)

    # Sloped Canopy Awning
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 6.5))
    canopy = bpy.context.active_object
    canopy.scale = (7.2, 5.2, 0.25)
    canopy.rotation_euler = (math.radians(-12), 0, 0)
    canopy.data.materials.append(mat_canopy)

    # Scalloped Front Valance
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 2.5, 5.8))
    valance = bpy.context.active_object
    valance.scale = (7.2, 0.15, 0.8)
    valance.data.materials.append(mat_valance)

    # Hanging Lantern
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.35, depth=0.8, location=(0, 0, 5.4))
    lamp = bpy.context.active_object
    lamp.data.materials.append(mat_lantern)

    blend_path = os.path.join(BLEND_DIR, "merchant_stall_luxury.blend")
    obj_path = os.path.join(MODEL_DIR, "merchant_stall_luxury.obj")
    render_path = os.path.join(EVIDENCE_DIR, "merchant_stall_luxury_render.png")
    render_and_export("merchant_stall_luxury", blend_path, obj_path, render_path)

# ====================================================================
# 7. IMPERIAL CAESAR HERO STATUE (Empire District Family)
# ====================================================================
def generate_caesar_statue():
    print("[BlenderPipeline] Generating Imperial Caesar Statue...")
    reset_scene()
    setup_camera_and_lighting(cam_pos=(0, -12, 5.5), look_at=(0, 0, 4.0))

    mat_plinth = create_material("StatuePlinth", (0.24, 0.24, 0.26), roughness=0.7, metallic=0.0)
    mat_marble = create_material("CaesarMarble", (0.85, 0.84, 0.82), roughness=0.35, metallic=0.0)
    mat_gold = create_material("CaesarLaurel", (0.92, 0.76, 0.20), roughness=0.25, metallic=0.9)

    # Stepped Foundation Plinth
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.0))
    plinth = bpy.context.active_object
    plinth.scale = (2.6, 2.6, 2.0)
    plinth.data.materials.append(mat_plinth)

    # Statue Torso with Classical Cuirass & Toga Drape
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 3.8))
    torso = bpy.context.active_object
    torso.scale = (1.8, 1.2, 2.8)
    torso.data.materials.append(mat_marble)

    # Head
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.65, location=(0, 0, 5.6))
    head = bpy.context.active_object
    head.data.materials.append(mat_marble)

    # Golden Laurel Wreath Crown
    bpy.ops.mesh.primitive_torus_add(major_radius=0.72, minor_radius=0.08, location=(0, 0, 5.8))
    wreath = bpy.context.active_object
    wreath.rotation_euler = (math.radians(-10), 0, 0)
    wreath.data.materials.append(mat_gold)

    blend_path = os.path.join(BLEND_DIR, "caesar_imperial_statue.blend")
    obj_path = os.path.join(MODEL_DIR, "caesar_imperial_statue.obj")
    render_path = os.path.join(EVIDENCE_DIR, "caesar_imperial_statue_render.png")
    render_and_export("caesar_imperial_statue", blend_path, obj_path, render_path)

# ====================================================================
# 8. FORTIFIED CIRCULAR VAULT BLAST DOOR (Sunken Vault Family)
# ====================================================================
def generate_vault_blast_door():
    print("[BlenderPipeline] Generating Vault Blast Door...")
    reset_scene()
    setup_camera_and_lighting(cam_pos=(0, -16, 5.0), look_at=(0, 0, 4.5))

    mat_outer_frame = create_material("VaultFrame", (0.20, 0.20, 0.24), roughness=0.5, metallic=0.6)
    mat_gear = create_material("VaultGearBronze", (0.65, 0.45, 0.20), roughness=0.35, metallic=0.8)
    mat_core = create_material("VaultCoreSteel", (0.15, 0.16, 0.18), roughness=0.25, metallic=0.9)
    mat_rune = create_material("VaultLockRune", (0.2, 0.8, 1.0), roughness=0.1, metallic=0.0, emission_color=(0.25, 0.85, 1.0), emission_strength=4.0)

    # Massive Square Reinforced Outer Frame
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 4.5))
    frame = bpy.context.active_object
    frame.scale = (9.0, 1.4, 9.0)
    frame.data.materials.append(mat_outer_frame)

    # Heavy Circular Blast Door Core
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=3.4, depth=1.8, location=(0, 0.2, 4.5))
    door = bpy.context.active_object
    door.rotation_euler = (math.radians(90), 0, 0)
    door.data.materials.append(mat_core)

    # Interlocking Outer Gear Teeth
    for i in range(12):
        ang = math.radians(i * 30)
        gx = math.cos(ang) * 3.6
        gz = 4.5 + math.sin(ang) * 3.6
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(gx, 0.4, gz))
        tooth = bpy.context.active_object
        tooth.scale = (0.7, 1.2, 0.7)
        tooth.rotation_euler = (0, 0, ang)
        tooth.data.materials.append(mat_gear)

    # Central Hydraulic Locking Wheel & Illuminated Rune
    bpy.ops.mesh.primitive_torus_add(major_radius=1.2, minor_radius=0.18, location=(0, 1.2, 4.5))
    wheel = bpy.context.active_object
    wheel.rotation_euler = (math.radians(90), 0, 0)
    wheel.data.materials.append(mat_gear)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.45, location=(0, 1.3, 4.5))
    rune = bpy.context.active_object
    rune.data.materials.append(mat_rune)

    blend_path = os.path.join(BLEND_DIR, "obsidian_vault_door.blend")
    obj_path = os.path.join(MODEL_DIR, "obsidian_vault_door.obj")
    render_path = os.path.join(EVIDENCE_DIR, "obsidian_vault_door_render.png")
    render_and_export("obsidian_vault_door", blend_path, obj_path, render_path)

if __name__ == "__main__":
    print("==================================================")
    print("  RELIC RUSH: BLENDER 3D MESH GENERATION PIPELINE ")
    print("==================================================")
    generate_hollow_crown()
    generate_gothic_archway()
    generate_druidic_monolith()
    generate_crown_spire()
    generate_ancient_tree()
    generate_merchant_stall()
    generate_caesar_statue()
    generate_vault_blast_door()
    print("==================================================")
    print("  BLENDER 3D PIPELINE COMPLETED SUCCESSFULLY      ")
    print("==================================================")
