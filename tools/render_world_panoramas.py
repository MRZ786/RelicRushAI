"""
tools/render_world_panoramas.py
Authoritative Cinematic World Panorama Pipeline for Relic Rush
Renders 1920x1080 visual evidence of all 5 full game environments:
1. Forgotten Market Hub & Base District
2. Whispering Wilds (Forgotten Wilds)
3. Ashen Domain (Empire District)
4. Sunken Vault (Obsidian Outpost Heist Fortress)
5. Celestial Rift (Hollow Realm)
"""

import bpy
import math
import os
import sys
import mathutils

BASE_DIR = r"C:\RelicRushAI"
EVIDENCE_DIR = os.path.join(BASE_DIR, "assets", "evidence")
os.makedirs(EVIDENCE_DIR, exist_ok=True)

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

def setup_camera(cam_pos, look_at, fov=45):
    cam_data = bpy.data.cameras.new(name="RenderCam")
    cam_data.lens = fov
    cam_data.clip_start = 0.1
    cam_data.clip_end = 2000
    cam_obj = bpy.data.objects.new(name="RenderCam", object_data=cam_data)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    
    cam_obj.location = cam_pos
    direction = (look_at[0] - cam_pos[0], look_at[1] - cam_pos[1], look_at[2] - cam_pos[2])
    cam_obj.rotation_mode = 'QUATERNION'
    cam_obj.rotation_quaternion = direction_to_quaternion(direction)
    return cam_obj

def add_sun_light(name, color, energy, direction):
    sun_data = bpy.data.lights.new(name=name, type='SUN')
    sun_data.energy = energy
    sun_data.color = color
    sun_obj = bpy.data.objects.new(name=name, object_data=sun_data)
    bpy.context.scene.collection.objects.link(sun_obj)
    sun_obj.rotation_mode = 'QUATERNION'
    sun_obj.rotation_quaternion = direction_to_quaternion(direction)
    return sun_obj

def create_material(name, color, roughness=0.4, metallic=0.0, emission_color=None, emission_strength=0.0, alpha=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
        if "Alpha" in bsdf.inputs:
            bsdf.inputs["Alpha"].default_value = alpha
        if emission_color and emission_strength > 0:
            if "Emission Color" in bsdf.inputs:
                bsdf.inputs["Emission Color"].default_value = (*emission_color, 1.0)
                bsdf.inputs["Emission Strength"].default_value = emission_strength
            elif "Emission" in bsdf.inputs:
                bsdf.inputs["Emission"].default_value = (*emission_color, 1.0)
    return mat

def add_box(name, loc, size, mat):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    obj.data.materials.append(mat)
    return obj

def add_cylinder(name, loc, radius, depth, mat, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=loc, rotation=rot)
    obj = bpy.context.active_object
    obj.name = name
    obj.data.materials.append(mat)
    return obj

def add_icosphere(name, loc, radius, mat):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=radius, subdivisions=2, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.data.materials.append(mat)
    return obj

# ======================================================================
# 1. SCENE: FORGOTTEN MARKET HUB & BASE DISTRICT
# ======================================================================
def render_market_hub():
    print("[Panorama] Rendering 1: Forgotten Market Hub...")
    reset_scene()
    setup_camera(cam_pos=(0, -78, 22), look_at=(0, 0, 6), fov=40)
    add_sun_light("SunsetSun", (1.0, 0.82, 0.65), 3.8, (0.5, 0.8, -0.6))
    add_sun_light("TwilightBounce", (0.35, 0.45, 0.65), 1.4, (-0.5, -0.8, 0.6))

    mat_bedrock = create_material("Bedrock", (0.18, 0.18, 0.20), 0.8)
    mat_cobble = create_material("Cobble", (0.28, 0.27, 0.29), 0.7)
    mat_marble = create_material("Marble", (0.72, 0.70, 0.66), 0.3)
    mat_slate = create_material("Slate", (0.17, 0.17, 0.19), 0.6)
    mat_water = create_material("Water", (0.05, 0.65, 0.80), 0.1, alpha=0.7, emission_color=(0.05, 0.65, 0.80), emission_strength=0.8)
    mat_gold = create_material("Gold", (0.95, 0.80, 0.22), 0.2, metallic=0.9)
    mat_obsidian = create_material("Obsidian", (0.08, 0.07, 0.10), 0.2, metallic=0.3)
    mat_ruby = create_material("Ruby", (0.92, 0.12, 0.35), 0.2, emission_color=(0.92, 0.12, 0.35), emission_strength=2.5)
    mat_blue_fire = create_material("BlueFire", (0.25, 0.75, 1.0), 0.1, emission_color=(0.25, 0.75, 1.0), emission_strength=4.0)
    mat_wood = create_material("Wood", (0.30, 0.20, 0.12), 0.8)
    mat_timber_white = create_material("TimberWall", (0.78, 0.75, 0.70), 0.7)
    mat_roof = create_material("RoofSlate", (0.22, 0.18, 0.24), 0.6)

    # Plaza Foundations & Radial Rings
    add_box("PlazaBedrock", (0, 0, -2), (180, 180, 4), mat_bedrock)
    add_cylinder("CobbleOuterRing", (0, 0, 0.2), radius=38, depth=0.4, mat=mat_cobble)
    add_cylinder("MarbleMidRing", (0, 0, 0.4), radius=27, depth=0.4, mat=mat_marble)
    add_cylinder("SlateInnerRing", (0, 0, 0.6), radius=18, depth=0.4, mat=mat_slate)

    # Central Reflecting Pool
    add_cylinder("PoolRim", (0, 0, 1.2), radius=13, depth=1.2, mat=mat_marble)
    add_cylinder("PoolWater", (0, 0, 1.6), radius=11.5, depth=0.5, mat=mat_water)

    # Hollow Crown Pedestal & Relic
    add_box("PedestalBase", (0, 0, 3.5), (4, 4, 3.2), mat_obsidian)
    add_box("PedestalGoldCap", (0, 0, 5.2), (4.4, 4.4, 0.4), mat_gold)
    add_cylinder("CrownCirclet", (0, 0, 6.2), radius=1.6, depth=0.5, mat=mat_obsidian)
    add_cylinder("CrownGoldTrim", (0, 0, 6.5), radius=1.7, depth=0.2, mat=mat_gold)
    for i in range(8):
        ang = i * (math.pi * 2 / 8)
        px = math.cos(ang) * 1.5
        py = math.sin(ang) * 1.5
        add_cylinder(f"CrownSpike_{i}", (px, py, 7.3), radius=0.15, depth=1.6, mat=mat_gold)
        add_icosphere(f"Ruby_{i}", (px, py, 8.2), radius=0.25, mat=mat_ruby)

    # 4 Cardinal Obelisks with Blue Flame
    ob_coords = [(-16, -16), (16, -16), (-16, 16), (16, 16)]
    for i, (ox, oy) in enumerate(ob_coords):
        add_box(f"Obelisk_{i}", (ox, oy, 7), (2.8, 2.8, 14), mat_slate)
        add_box(f"ObCollar_{i}", (ox, oy, 13.5), (3.2, 3.2, 0.8), mat_gold)
        add_icosphere(f"Flame_{i}", (ox, oy, 15), radius=1.2, mat=mat_blue_fire)

    # Clocktower on the right (28, 42)
    add_box("ClockBase", (28, 42, 9), (12, 12, 18), mat_slate)
    add_box("ClockTier2", (28, 42, 22), (10, 10, 8), mat_marble)
    add_cylinder("ClockFace", (28, 36.8, 22), radius=3.2, depth=0.6, mat=mat_gold, rot=(math.pi/2, 0, 0))
    add_box("ClockSpire", (28, 42, 31), (8, 8, 10), mat_roof)

    # Brimstone Bob's Antiquities Guildhall (42, -26)
    add_box("BobFloor", (42, -26, 0.4), (22, 20, 0.8), mat_wood)
    add_box("BobWallBack", (42, -36, 7), (22, 1, 14), mat_timber_white)
    add_box("BobWallSide", (53, -26, 7), (1, 20, 14), mat_timber_white)
    add_box("BobRoof", (42, -26, 16), (24, 22, 5), mat_roof)
    add_box("BobCounter", (40, -22, 2), (8, 3, 3), mat_wood)

    # Perimeter Wall & Gateway
    add_box("GateWallL", (-35, 65, 8), (45, 4, 16), mat_slate)
    add_box("GateWallR", (35, 65, 8), (45, 4, 16), mat_slate)
    add_box("GateTowerL", (-16, 65, 15), (10, 10, 30), mat_slate)
    add_box("GateTowerR", (16, 65, 15), (10, 10, 30), mat_slate)
    add_box("GateArch", (0, 65, 23), (24, 6, 6), mat_marble)

    render_path = os.path.join(EVIDENCE_DIR, "scene_forgotten_market_hub.png")
    bpy.context.scene.render.filepath = render_path
    bpy.ops.render.render(write_still=True)
    print(f"[Panorama] Rendered {render_path}")

# ======================================================================
# 2. SCENE: WHISPERING WILDS (FORGOTTEN WILDS)
# ======================================================================
def render_whispering_wilds():
    print("[Panorama] Rendering 2: Whispering Wilds...")
    reset_scene()
    setup_camera(cam_pos=(0, -75, 18), look_at=(0, 0, 16), fov=45)
    add_sun_light("ForestSun", (0.75, 1.0, 0.80), 2.8, (0.4, 0.6, -0.7))
    add_sun_light("MossBounce", (0.2, 0.45, 0.25), 1.6, (-0.4, -0.6, 0.5))

    mat_grass = create_material("WildGrass", (0.16, 0.24, 0.14), 0.9)
    mat_bark = create_material("IronwoodBark", (0.18, 0.12, 0.08), 0.8)
    mat_leaves = create_material("CanopyLeaves", (0.12, 0.32, 0.15), 0.7)
    mat_mossy_stone = create_material("MossyStone", (0.26, 0.30, 0.25), 0.7)
    mat_green_rune = create_material("GreenRune", (0.25, 0.95, 0.40), 0.2, emission_color=(0.25, 0.95, 0.40), emission_strength=4.5)
    mat_sandstone = create_material("Sandstone", (0.65, 0.55, 0.38), 0.8)
    mat_gold = create_material("HourglassGold", (0.92, 0.78, 0.22), 0.3, metallic=0.8)

    # Forest Ground & Cliffs
    add_box("ForestFloor", (0, 0, -1), (180, 180, 2), mat_grass)
    add_box("BackCliff", (0, 75, 18), (180, 15, 38), mat_mossy_stone)
    add_box("LeftCliff", (-75, 0, 18), (15, 180, 38), mat_mossy_stone)

    # Rolling Grass Knolls
    add_cylinder("Knoll1", (-32, -18, 1), radius=16, depth=3, mat=mat_grass)
    add_cylinder("Knoll2", (30, 15, 1.2), radius=18, depth=3.5, mat=mat_grass)

    # Ancient Wispwood / Elder Ironwood Tree (Center)
    add_cylinder("TreeTrunk", (0, 0, 22), radius=4.5, depth=44, mat=mat_bark)
    # Buttress roots
    for i in range(5):
        ang = i * (math.pi * 2 / 5)
        rx = math.cos(ang) * 6
        ry = math.sin(ang) * 6
        add_box(f"Root_{i}", (rx, ry, 3), (2.5, 2.5, 6), mat_bark)
    # Massive multi-layer canopy
    add_cylinder("Canopy1", (0, 0, 38), radius=24, depth=10, mat=mat_leaves)
    add_cylinder("Canopy2", (0, 0, 46), radius=18, depth=8, mat=mat_leaves)
    add_cylinder("Canopy3", (0, 0, 52), radius=11, depth=6, mat=mat_leaves)

    # 6 Druidic Standing Stones in Circle
    radius = 18
    for s in range(6):
        ang = s * (math.pi * 2 / 6)
        sx = math.cos(ang) * radius
        sy = math.sin(ang) * radius
        add_box(f"DruidStone_{s}", (sx, sy, 5.5), (2.8, 2.0, 11), mat_mossy_stone)
        add_box(f"RuneBand_{s}", (sx, sy, 6.5), (3.0, 2.2, 1.4), mat_green_rune)

    # Shrine of Shifting Sands & Hourglass Altar (Left foreground)
    add_box("ShrineBase", (-28, -32, 1.2), (18, 18, 2.4), mat_sandstone)
    for c in [(-35, -39), (-21, -39), (-35, -25), (-21, -25)]:
        add_cylinder(f"ShrineCol_{c}", (c[0], c[1], 5.5), radius=0.9, depth=8, mat=mat_sandstone)
    add_box("HourglassAltar", (-28, -32, 3.2), (4, 4, 3.0), mat_gold)

    # Mossy Boulders & Fallen Hollow Log
    add_box("Boulder1", (25, -28, 3), (7, 6, 6), mat_mossy_stone)
    add_box("Boulder2", (30, -24, 2), (5, 5, 4), mat_mossy_stone)
    add_cylinder("FallenLog", (18, -38, 2), radius=1.8, depth=16, mat=mat_bark, rot=(0, math.pi/2, 0.3))

    render_path = os.path.join(EVIDENCE_DIR, "scene_whispering_wilds.png")
    bpy.context.scene.render.filepath = render_path
    bpy.ops.render.render(write_still=True)
    print(f"[Panorama] Rendered {render_path}")

# ======================================================================
# 3. SCENE: ASHEN DOMAIN (EMPIRE DISTRICT)
# ======================================================================
def render_ashen_domain():
    print("[Panorama] Rendering 3: Ashen Domain...")
    reset_scene()
    setup_camera(cam_pos=(0, -85, 20), look_at=(0, 20, 14), fov=42)
    add_sun_light("ImperialSun", (1.0, 0.70, 0.45), 3.5, (0.3, 0.8, -0.6))
    add_sun_light("AshBounce", (0.3, 0.25, 0.25), 1.5, (-0.3, -0.8, 0.5))

    mat_ash_ground = create_material("AshGround", (0.19, 0.19, 0.21), 0.8)
    mat_flagstone = create_material("Flagstone", (0.28, 0.27, 0.29), 0.7)
    mat_curb = create_material("MarbleCurb", (0.75, 0.72, 0.68), 0.3)
    mat_basilica = create_material("BasilicaStone", (0.70, 0.68, 0.66), 0.4)
    mat_gold = create_material("ImperialGold", (0.90, 0.75, 0.18), 0.2, metallic=0.9)
    mat_lava = create_material("MoltenLava", (1.0, 0.35, 0.05), 0.2, emission_color=(1.0, 0.35, 0.05), emission_strength=5.0)
    mat_crimson = create_material("PraetorianCrimson", (0.65, 0.15, 0.18), 0.6)
    mat_iron = create_material("ImperialIron", (0.22, 0.23, 0.26), 0.4, metallic=0.8)

    # Ashen Ground Foundation
    add_box("Ground", (0, 0, -1), (180, 200, 2), mat_ash_ground)

    # Avenue of the Caesars
    add_box("AvenueBoulevard", (0, 0, 0.2), (28, 190, 0.4), mat_flagstone)
    add_box("CurbL", (-14.5, 0, 0.5), (1.5, 190, 0.8), mat_curb)
    add_box("CurbR", (14.5, 0, 0.5), (1.5, 190, 0.8), mat_curb)

    # Triumphal Imperial Gatehouse (Foreground Entry)
    add_box("GateL_Pillar", (-16, -60, 12), (6, 6, 24), mat_basilica)
    add_box("GateR_Pillar", (16, -60, 12), (6, 6, 24), mat_basilica)
    add_box("GateLintel", (0, -60, 24), (38, 7, 6), mat_basilica)
    add_box("GatePediment", (0, -60, 28), (40, 8, 3), mat_gold)

    # Avenue of Caesar Statues flanking the boulevard
    for i, y_pos in enumerate([-35, -5, 25, 55]):
        # Left Statue
        add_box(f"CaesarPed_L_{i}", (-19, y_pos, 2.5), (4, 4, 5), mat_curb)
        add_cylinder(f"CaesarTorso_L_{i}", (-19, y_pos, 7), radius=1.2, depth=4, mat=mat_curb)
        add_icosphere(f"CaesarHead_L_{i}", (-19, y_pos, 9.8), radius=0.9, mat=mat_curb)
        add_cylinder(f"Wreath_L_{i}", (-19, y_pos, 10.3), radius=1.1, depth=0.3, mat=mat_gold)

        # Right Statue
        add_box(f"CaesarPed_R_{i}", (19, y_pos, 2.5), (4, 4, 5), mat_curb)
        add_cylinder(f"CaesarTorso_R_{i}", (19, y_pos, 7), radius=1.2, depth=4, mat=mat_curb)
        add_icosphere(f"CaesarHead_R_{i}", (19, y_pos, 9.8), radius=0.9, mat=mat_curb)
        add_cylinder(f"Wreath_R_{i}", (19, y_pos, 10.3), radius=1.1, depth=0.3, mat=mat_gold)

    # Imperial Curia Basilica (End of Avenue: Y = 85)
    add_box("CuriaPodium", (0, 85, 2), (64, 32, 4), mat_curb)
    # 8 Corinthian Portico Columns
    for col in range(8):
        cx = -28 + col * 8
        add_cylinder(f"CuriaCol_{col}", (cx, 75, 12), radius=1.2, depth=18, mat=mat_basilica)
    add_box("CuriaEntablature", (0, 75, 22), (64, 12, 3), mat_curb)
    add_box("CuriaPedimentGold", (0, 75, 25), (66, 13, 3.5), mat_gold)
    add_box("CuriaBackWall", (0, 92, 16), (62, 4, 28), mat_basilica)

    # Monumental Aqueduct (West Flank: X = -55)
    for p in range(6):
        py = -50 + p * 26
        add_box(f"AqueductPier_{p}", (-55, py, 10), (4, 4, 20), mat_basilica)
    add_box("AqueductTrough", (-55, 15, 21), (5, 170, 3), mat_curb)

    # Volcanic Fissures with Molten Magma
    add_box("FissureL", (-38, 10, 0.1), (3, 40, 0.4), mat_lava)
    add_box("FissureR", (38, 10, 0.1), (3, 35, 0.4), mat_lava)

    render_path = os.path.join(EVIDENCE_DIR, "scene_ashen_domain_avenue.png")
    bpy.context.scene.render.filepath = render_path
    bpy.ops.render.render(write_still=True)
    print(f"[Panorama] Rendered {render_path}")

# ======================================================================
# 4. SCENE: SUNKEN VAULT (OBSIDIAN OUTPOST HEIST FORTRESS)
# ======================================================================
def render_sunken_vault():
    print("[Panorama] Rendering 4: Sunken Vault Fortress...")
    reset_scene()
    setup_camera(cam_pos=(-55, -85, 45), look_at=(0, 0, 18), fov=44)
    add_sun_light("MoonLight", (0.45, 0.55, 0.75), 2.2, (0.5, 0.6, -0.6))
    add_sun_light("SearchlightBounce", (1.0, 0.95, 0.80), 2.0, (-0.4, -0.7, 0.6))

    mat_dark_slate = create_material("DarkSlate", (0.16, 0.16, 0.19), 0.6)
    mat_talus = create_material("TalusBase", (0.22, 0.22, 0.25), 0.7)
    mat_moat = create_material("MoatFloor", (0.08, 0.08, 0.10), 0.9)
    mat_wood = create_material("BridgeOak", (0.35, 0.24, 0.15), 0.8)
    mat_metal = create_material("ChainIron", (0.35, 0.38, 0.42), 0.3, metallic=0.9)
    mat_bronze = create_material("VaultBronze", (0.75, 0.55, 0.25), 0.3, metallic=0.8)
    mat_red_light = create_material("AlarmRed", (1.0, 0.15, 0.15), 0.2, emission_color=(1.0, 0.15, 0.15), emission_strength=4.0)
    mat_searchlight = create_material("SearchLight", (1.0, 0.95, 0.80), 0.1, emission_color=(1.0, 0.95, 0.80), emission_strength=6.0)

    # Perimeter Dry Moat
    add_box("MoatFloor", (0, -50, -4), (160, 24, 2), mat_moat)

    # Heavy Oak Drawbridge
    add_box("Drawbridge", (0, -50, 1.5), (14, 24, 1.4), mat_wood)
    add_cylinder("BridgeChainL", (-6.5, -45, 9), radius=0.25, depth=18, mat=mat_metal, rot=(math.pi/5, 0, 0))
    add_cylinder("BridgeChainR", (6.5, -45, 9), radius=0.25, depth=18, mat=mat_metal, rot=(math.pi/5, 0, 0))

    # Twin Gatehouse Towers
    add_box("GatehouseL", (-16, -38, 16), (14, 14, 32), mat_dark_slate)
    add_box("GatehouseR", (16, -38, 16), (14, 14, 32), mat_dark_slate)
    add_box("GateArch", (0, -38, 26), (20, 6, 8), mat_talus)
    add_box("PortcullisIron", (0, -38, 11), (16, 1.2, 16), mat_metal)

    # Fortified Curtain Walls
    add_box("WallFrontL", (-45, -38, 13), (44, 6, 26), mat_dark_slate)
    add_box("WallFrontR", (45, -38, 13), (44, 6, 26), mat_dark_slate)
    add_box("WallLeft", (-65, 0, 13), (6, 76, 26), mat_dark_slate)
    add_box("WallRight", (65, 0, 13), (6, 76, 26), mat_dark_slate)

    # Octagonal Corner Bastions with Searchlights
    for b_pos in [(-65, -38), (65, -38), (-65, 38), (65, 38)]:
        add_cylinder(f"Bastion_{b_pos}", (b_pos[0], b_pos[1], 17), radius=7, depth=34, mat=mat_dark_slate)
        add_icosphere(f"Search_{b_pos}", (b_pos[0], b_pos[1], 35), radius=1.4, mat=mat_searchlight)

    # Grand Octagonal Vault Blast Door (Center background: Y = 25)
    add_cylinder("VaultDoorFrame", (0, 25, 11), radius=9, depth=2, mat=mat_dark_slate, rot=(math.pi/2, 0, 0))
    add_cylinder("VaultDoorCore", (0, 24, 11), radius=7, depth=2, mat=mat_metal, rot=(math.pi/2, 0, 0))
    add_cylinder("VaultLockWheel", (0, 22.8, 11), radius=2.5, depth=0.8, mat=mat_bronze, rot=(math.pi/2, 0, 0))
    # 12 Geared Blast Teeth
    for t in range(12):
        t_ang = t * (math.pi * 2 / 12)
        tx = math.cos(t_ang) * 7.5
        tz = 11 + math.sin(t_ang) * 7.5
        add_box(f"VaultTooth_{t}", (tx, 23.5, tz), (1.4, 1.8, 1.4), mat_bronze)

    # Tactical Cage Red Lanterns
    add_icosphere("RedAlarm1", (-12, -30, 8), radius=0.6, mat=mat_red_light)
    add_icosphere("RedAlarm2", (12, -30, 8), radius=0.6, mat=mat_red_light)

    render_path = os.path.join(EVIDENCE_DIR, "scene_sunken_vault_fortress.png")
    bpy.context.scene.render.filepath = render_path
    bpy.ops.render.render(write_still=True)
    print(f"[Panorama] Rendered {render_path}")

# ======================================================================
# 5. SCENE: CELESTIAL RIFT (HOLLOW REALM VOID DIMENSION)
# ======================================================================
def render_celestial_rift():
    print("[Panorama] Rendering 5: Celestial Rift...")
    reset_scene()
    setup_camera(cam_pos=(0, -85, 25), look_at=(0, 20, 28), fov=44)
    add_sun_light("CosmicLight", (0.60, 0.35, 0.90), 2.5, (0.4, 0.6, -0.6))
    add_sun_light("VoidGlow", (0.30, 0.15, 0.50), 1.8, (-0.4, -0.6, 0.5))

    mat_obsidian_island = create_material("VoidObsidian", (0.07, 0.06, 0.09), 0.2, metallic=0.5)
    mat_crag = create_material("VoidCrag", (0.12, 0.10, 0.15), 0.8)
    mat_light_bridge = create_material("LightBridge", (0.75, 0.35, 0.95), 0.1, alpha=0.5, emission_color=(0.75, 0.35, 0.95), emission_strength=4.0)
    mat_portal = create_material("VoidPortal", (0.65, 0.15, 0.85), 0.1, emission_color=(0.65, 0.15, 0.85), emission_strength=5.0)
    mat_spire = create_material("SpireObsidian", (0.05, 0.04, 0.07), 0.2, metallic=0.7)
    mat_gold_ring = create_material("SpireGold", (0.95, 0.80, 0.22), 0.2, metallic=0.9, emission_color=(0.95, 0.80, 0.22), emission_strength=1.5)
    mat_void_beacon = create_material("VoidBeacon", (0.85, 0.25, 1.0), 0.1, emission_color=(0.85, 0.25, 1.0), emission_strength=6.0)

    # 1. Arrival Island (Foreground: Y = -40)
    add_cylinder("ArrivalIsland", (0, -40, 2), radius=18, depth=4, mat=mat_obsidian_island)
    add_box("ArrivalCrag", (0, -40, -4), (24, 24, 8), mat_crag)
    # Return Void Portal
    add_box("PortalFrameL", (-6, -48, 8), (1.5, 1.5, 12), mat_spire)
    add_box("PortalFrameR", (6, -48, 8), (1.5, 1.5, 12), mat_spire)
    add_box("PortalCore", (0, -48, 8), (10, 0.8, 11), mat_portal)

    # Celestial Light Bridge 1 (Y: -22 to 0)
    add_box("LightBridge1", (0, -11, 2.5), (6, 22, 0.6), mat_light_bridge)

    # 2. Intermediate Island (Y = 12)
    add_cylinder("MidIsland", (0, 12, 4), radius=14, depth=4, mat=mat_obsidian_island)
    add_box("MidCrag", (0, 12, -2), (18, 18, 8), mat_crag)
    add_icosphere("VoidCacheCrystal", (0, 12, 8), radius=2.2, mat=mat_portal)

    # Celestial Light Bridge 2 (Y: 26 to 48)
    add_box("LightBridge2", (0, 37, 5.5), (6, 22, 0.6), mat_light_bridge)

    # 3. Apex Sanctuary Island (Background: Y = 68)
    add_cylinder("ApexIsland", (0, 68, 7), radius=22, depth=6, mat=mat_obsidian_island)
    add_box("ApexCrag", (0, 68, 0), (30, 30, 10), mat_crag)

    # Altar of The Hollow Crown
    add_cylinder("AltarBase", (0, 65, 11), radius=4, depth=2, mat=mat_spire)
    add_icosphere("HollowCrownLevitating", (0, 65, 14), radius=1.8, mat=mat_gold_ring)

    # Monumental Void Crown Spire (Y = 82)
    add_cylinder("SpireBase", (0, 82, 11), radius=6, depth=4, mat=mat_spire)
    add_cylinder("SpireNeedle", (0, 82, 34), radius=2.2, depth=44, mat=mat_spire)
    # 2 Concentric Orbital Rings
    add_cylinder("OrbitalRing1", (0, 82, 28), radius=8.5, depth=0.8, mat=mat_portal, rot=(math.pi/6, math.pi/8, 0))
    add_cylinder("OrbitalRing2", (0, 82, 40), radius=6.0, depth=0.6, mat=mat_gold_ring, rot=(-math.pi/5, -math.pi/6, 0))
    # Apex Void Beacon
    add_icosphere("BeaconOrb", (0, 82, 57), radius=2.5, mat=mat_void_beacon)

    render_path = os.path.join(EVIDENCE_DIR, "scene_celestial_rift_apex.png")
    bpy.context.scene.render.filepath = render_path
    bpy.ops.render.render(write_still=True)
    print(f"[Panorama] Rendered {render_path}")

# ======================================================================
# MAIN EXECUTION
# ======================================================================
if __name__ == "__main__":
    print("==================================================")
    print("  RELIC RUSH: 5-ZONE CINEMATIC PANORAMA PIPELINE  ")
    print("==================================================")
    render_market_hub()
    render_whispering_wilds()
    render_ashen_domain()
    render_sunken_vault()
    render_celestial_rift()
    print("All 5 zone panorama renders completed successfully!")
