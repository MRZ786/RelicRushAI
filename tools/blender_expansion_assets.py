"""
tools/blender_expansion_assets.py
Generates 4 major architectural and environmental 3D asset families for the Massive World Expansion:
1. monumental_watchtower (4-tier fortified stone/timber watchtower with battlements and searchlight cradle)
2. ancient_dolmen_shrine (Megalithic Celtic dolmen altar with weathered capstone and glowing runic carvings)
3. volcanic_skull_brazier (Ornate carved basalt brazier adorned with horned skull reliefs and burning magma core)
4. celestial_void_obelisk (Floating slender cosmic crystal obelisk with levitating shards and astral runes)

Exports .obj to assets/models/, .blend to assets/blender/, and Cycles .png to assets/evidence/.
"""

import bpy
import bmesh
import math
import os

MODELS_DIR = r"C:\RelicRushAI\assets\models"
BLENDER_DIR = r"C:\RelicRushAI\assets\blender"
EVIDENCE_DIR = r"C:\RelicRushAI\assets\evidence"

for d in [MODELS_DIR, BLENDER_DIR, EVIDENCE_DIR]:
    os.makedirs(d, exist_ok=True)

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    if hasattr(scene.cycles, 'device'):
        scene.cycles.device = 'CPU'
    scene.cycles.samples = 64
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080

def create_material(name, base_color, roughness=0.5, metallic=0.0, emission=None, emission_strength=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    
    out_node = nodes.new(type='ShaderNodeOutputMaterial')
    principled = nodes.new(type='ShaderNodeBsdfPrincipled')
    principled.inputs['Base Color'].default_value = base_color
    principled.inputs['Roughness'].default_value = roughness
    principled.inputs['Metallic'].default_value = metallic
    
    if emission:
        principled.inputs['Emission Color'].default_value = emission
        principled.inputs['Emission Strength'].default_value = emission_strength
        
    links.new(principled.outputs['BSDF'], out_node.inputs['Surface'])
    return mat

def setup_lighting_and_cam(cam_pos, cam_rot, light_energy=1500.0):
    cam_data = bpy.data.cameras.new("Camera")
    cam_obj = bpy.data.objects.new("Camera", cam_data)
    cam_obj.location = cam_pos
    cam_obj.rotation_euler = [math.radians(a) for a in cam_rot]
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    
    # Key light
    key_data = bpy.data.lights.new(name="KeyLight", type='POINT')
    key_data.energy = light_energy
    key_data.color = (1.0, 0.92, 0.8)
    key_obj = bpy.data.objects.new(name="KeyLight", object_data=key_data)
    key_obj.location = (cam_pos[0] + 5, cam_pos[1] - 5, cam_pos[2] + 8)
    bpy.context.scene.collection.objects.link(key_obj)
    
    # Fill light
    fill_data = bpy.data.lights.new(name="FillLight", type='POINT')
    fill_data.energy = light_energy * 0.4
    fill_data.color = (0.5, 0.7, 1.0)
    fill_obj = bpy.data.objects.new(name="FillLight", object_data=fill_data)
    fill_obj.location = (cam_pos[0] - 6, cam_pos[1] + 6, cam_pos[2] + 3)
    bpy.context.scene.collection.objects.link(fill_obj)
    
    # Rim light
    rim_data = bpy.data.lights.new(name="RimLight", type='POINT')
    rim_data.energy = light_energy * 0.7
    rim_data.color = (0.9, 0.6, 1.0)
    rim_obj = bpy.data.objects.new(name="RimLight", object_data=rim_data)
    rim_obj.location = (0, 0, cam_pos[2] + 6)
    bpy.context.scene.collection.objects.link(rim_obj)

def save_and_render(asset_id):
    obj_path = os.path.join(MODELS_DIR, f"{asset_id}.obj")
    blend_path = os.path.join(BLENDER_DIR, f"{asset_id}.blend")
    render_path = os.path.join(EVIDENCE_DIR, f"{asset_id}_render.png")
    
    # Export OBJ
    bpy.ops.wm.obj_export(filepath=obj_path)
    
    # Save Blend
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    
    # Render PNG
    bpy.context.scene.render.filepath = render_path
    bpy.ops.render.render(write_still=True)
    print(f"[EXPORTED] {asset_id} -> OBJ: {obj_path}, BLEND: {blend_path}, RENDER: {render_path}")

# ==============================================================================
# ASSET 1: MONUMENTAL WATCHTOWER
# ==============================================================================
def build_monumental_watchtower():
    print("Building Monumental Watchtower...")
    reset_scene()
    
    mat_stone = create_material("TowerStone", (0.22, 0.22, 0.25, 1.0), roughness=0.85)
    mat_wood = create_material("TowerWood", (0.35, 0.22, 0.14, 1.0), roughness=0.7)
    mat_iron = create_material("TowerIron", (0.12, 0.12, 0.14, 1.0), roughness=0.3, metallic=0.9)
    mat_gold = create_material("TowerGold", (0.85, 0.68, 0.18, 1.0), roughness=0.25, metallic=0.95)
    mat_beacon = create_material("TowerBeacon", (1.0, 0.6, 0.1, 1.0), emission=(1.0, 0.6, 0.1, 1.0), emission_strength=4.0)
    
    # Tier 1: Sloped Stone Talus Base
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=6.0, radius2=4.8, depth=8.0, location=(0, 0, 4.0))
    talus = bpy.context.active_object
    talus.name = "Tower_TalusBase"
    talus.data.materials.append(mat_stone)
    
    # Tier 2: Mid Wall Section with Arrow Slits
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=4.6, depth=10.0, location=(0, 0, 13.0))
    mid_shaft = bpy.context.active_object
    mid_shaft.name = "Tower_MidShaft"
    mid_shaft.data.materials.append(mat_stone)
    
    # Decorative Stone Belt Course
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=5.0, depth=1.0, location=(0, 0, 18.5))
    belt = bpy.context.active_object
    belt.name = "Tower_BeltCourse"
    belt.data.materials.append(mat_gold)
    
    # Tier 3: Corbelled Upper Bastion Platform
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=4.8, radius2=6.4, depth=3.0, location=(0, 0, 20.0))
    corbel = bpy.context.active_object
    corbel.name = "Tower_Corbel"
    corbel.data.materials.append(mat_stone)
    
    # Upper Battlement Floor
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=6.5, depth=0.8, location=(0, 0, 21.8))
    plat = bpy.context.active_object
    plat.name = "Tower_Platform"
    plat.data.materials.append(mat_wood)
    
    # Crenellated Parapet Posts (8 posts)
    for i in range(8):
        ang = i * (math.pi / 4)
        px = math.cos(ang) * 6.2
        py = math.sin(ang) * 6.2
        bpy.ops.mesh.primitive_cube_add(size=1.2, location=(px, py, 23.0))
        post = bpy.context.active_object
        post.scale = (0.8, 0.8, 1.5)
        post.data.materials.append(mat_stone)
        
    # Tier 4: Timber Roof Spire & Beacon Cradle
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=6.8, radius2=0.2, depth=7.0, location=(0, 0, 27.5))
    roof = bpy.context.active_object
    roof.name = "Tower_RoofSpire"
    roof.data.materials.append(mat_wood)
    
    # Apex Golden Finial & Beacon Orb
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.9, location=(0, 0, 31.5))
    beacon = bpy.context.active_object
    beacon.name = "Tower_BeaconOrb"
    beacon.data.materials.append(mat_beacon)
    
    setup_lighting_and_cam((18, -22, 20), (60, 0, 40), light_energy=2200.0)
    save_and_render("monumental_watchtower")

# ==============================================================================
# ASSET 2: ANCIENT DOLMEN SHRINE
# ==============================================================================
def build_ancient_dolmen_shrine():
    print("Building Ancient Dolmen Shrine...")
    reset_scene()
    
    mat_weathered_stone = create_material("DolmenStone", (0.32, 0.35, 0.30, 1.0), roughness=0.9)
    mat_moss = create_material("DolmenMoss", (0.18, 0.38, 0.15, 1.0), roughness=0.95)
    mat_rune = create_material("DolmenRune", (0.2, 0.9, 0.4, 1.0), emission=(0.2, 0.9, 0.4, 1.0), emission_strength=5.0)
    
    # Stepped Foundation Mound
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=7.5, depth=1.0, location=(0, 0, 0.5))
    mound = bpy.context.active_object
    mound.data.materials.append(mat_moss)
    
    # Left Megalithic Upright Post
    bpy.ops.mesh.primitive_cube_add(size=2.0, location=(-3.2, 0, 3.5))
    post_l = bpy.context.active_object
    post_l.scale = (1.4, 1.8, 3.2)
    post_l.rotation_euler = (0.05, -0.04, 0.1)
    post_l.data.materials.append(mat_weathered_stone)
    
    # Right Megalithic Upright Post
    bpy.ops.mesh.primitive_cube_add(size=2.0, location=(3.2, 0, 3.5))
    post_r = bpy.context.active_object
    post_r.scale = (1.4, 1.8, 3.2)
    post_r.rotation_euler = (-0.04, 0.05, -0.08)
    post_r.data.materials.append(mat_weathered_stone)
    
    # Massive Weathered Capstone Slab
    bpy.ops.mesh.primitive_cube_add(size=2.0, location=(0, 0, 7.2))
    cap = bpy.context.active_object
    cap.scale = (4.8, 3.2, 0.9)
    cap.rotation_euler = (0.02, 0.03, -0.02)
    cap.data.materials.append(mat_weathered_stone)
    
    # Glowing Runic Band Inlaid into Capstone
    bpy.ops.mesh.primitive_torus_add(major_radius=3.0, minor_radius=0.15, location=(0, 0, 7.3))
    rune_band = bpy.context.active_object
    rune_band.scale = (1.2, 0.8, 1.0)
    rune_band.data.materials.append(mat_rune)
    
    # Central Offering Altar Stone Beneath Capstone
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=1.6, depth=1.8, location=(0, 0, 1.8))
    altar = bpy.context.active_object
    altar.data.materials.append(mat_weathered_stone)
    
    # Levitating Spore Core above Altar
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.6, location=(0, 0, 3.6))
    core = bpy.context.active_object
    core.data.materials.append(mat_rune)
    
    setup_lighting_and_cam((10, -12, 9), (65, 0, 40), light_energy=1800.0)
    save_and_render("ancient_dolmen_shrine")

# ==============================================================================
# ASSET 3: VOLCANIC SKULL BRAZIER
# ==============================================================================
def build_volcanic_skull_brazier():
    print("Building Volcanic Skull Brazier...")
    reset_scene()
    
    mat_basalt = create_material("BrazierBasalt", (0.12, 0.11, 0.14, 1.0), roughness=0.8)
    mat_obsidian = create_material("BrazierObsidian", (0.08, 0.08, 0.10, 1.0), roughness=0.15, metallic=0.7)
    mat_magma = create_material("BrazierMagma", (1.0, 0.25, 0.02, 1.0), emission=(1.0, 0.35, 0.05, 1.0), emission_strength=6.0)
    mat_fire = create_material("BrazierFire", (1.0, 0.8, 0.1, 1.0), emission=(1.0, 0.8, 0.1, 1.0), emission_strength=8.0)
    
    # Octagonal Stepped Plinth Base
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=3.2, depth=0.8, location=(0, 0, 0.4))
    base = bpy.context.active_object
    base.data.materials.append(mat_basalt)
    
    # Fluted Brazier Pillar Stem
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=2.4, radius2=1.8, depth=4.0, location=(0, 0, 2.8))
    stem = bpy.context.active_object
    stem.data.materials.append(mat_basalt)
    
    # Flaring Horned Caldera Basin
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=1.8, radius2=3.6, depth=2.4, location=(0, 0, 5.8))
    basin = bpy.context.active_object
    basin.data.materials.append(mat_obsidian)
    
    # 4 Horned Demon Skull Carvings on Basin Facets
    for i in range(4):
        ang = i * (math.pi / 2)
        sx = math.cos(ang) * 3.2
        sy = math.sin(ang) * 3.2
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.7, location=(sx, sy, 6.2))
        skull = bpy.context.active_object
        skull.scale = (0.7, 0.7, 1.1)
        skull.data.materials.append(mat_basalt)
        # Horns
        for h_dir in [-0.4, 0.4]:
            hx = sx + math.cos(ang + math.pi/2) * h_dir
            hy = sy + math.sin(ang + math.pi/2) * h_dir
            bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.2, radius2=0.05, depth=0.9, location=(hx, hy, 7.0))
            horn = bpy.context.active_object
            horn.data.materials.append(mat_obsidian)
            
    # Molten Magma Reservoir inside Basin
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=2.8, depth=0.6, location=(0, 0, 6.6))
    magma = bpy.context.active_object
    magma.data.materials.append(mat_magma)
    
    # Roaring Flame Cluster
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.4, location=(0, 0, 7.8))
    flame = bpy.context.active_object
    flame.scale = (0.9, 0.9, 1.6)
    flame.data.materials.append(mat_fire)
    
    setup_lighting_and_cam((7, -8, 8), (65, 0, 40), light_energy=1600.0)
    save_and_render("volcanic_skull_brazier")

# ==============================================================================
# ASSET 4: CELESTIAL VOID OBELISK
# ==============================================================================
def build_celestial_void_obelisk():
    print("Building Celestial Void Obelisk...")
    reset_scene()
    
    mat_void_obsidian = create_material("VoidObsidian", (0.06, 0.05, 0.09, 1.0), roughness=0.2, metallic=0.8)
    mat_crystal = create_material("VoidCrystal", (0.6, 0.15, 0.85, 1.0), roughness=0.1, emission=(0.7, 0.2, 0.95, 1.0), emission_strength=4.0)
    mat_nebula_glow = create_material("NebulaGlow", (0.2, 0.8, 1.0, 1.0), emission=(0.2, 0.8, 1.0, 1.0), emission_strength=7.0)
    
    # Levitating Octagonal Base Ring (unanchored feel)
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=2.5, depth=0.8, location=(0, 0, 1.0))
    base = bpy.context.active_object
    base.data.materials.append(mat_void_obsidian)
    
    # Lower Inverted Pyramid Tip (levitating above base)
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.2, radius2=1.4, depth=2.0, location=(0, 0, 3.2))
    lower_tip = bpy.context.active_object
    lower_tip.data.materials.append(mat_void_obsidian)
    
    # Slender Tapering Obelisk Shaft
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=1.4, radius2=0.8, depth=9.0, location=(0, 0, 8.5))
    shaft = bpy.context.active_object
    shaft.data.materials.append(mat_void_obsidian)
    
    # Pyramidal Apex Capstone
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.8, radius2=0.05, depth=2.2, location=(0, 0, 14.0))
    cap = bpy.context.active_object
    cap.data.materials.append(mat_crystal)
    
    # 4 Levitating Crystal Shards Orbiting Mid-Shaft
    for i in range(4):
        ang = i * (math.pi / 2) + math.pi/4
        cx = math.cos(ang) * 2.4
        cy = math.sin(ang) * 2.4
        bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.35, radius2=0.05, depth=2.2, location=(cx, cy, 8.5))
        shard = bpy.context.active_object
        shard.scale = (0.7, 0.7, 1.4)
        shard.rotation_euler = (0.2 * math.cos(ang), 0.2 * math.sin(ang), ang)
        shard.data.materials.append(mat_crystal)
        
    # Central Pulsing Nebula Singularity Core
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.55, location=(0, 0, 8.5))
    singularity = bpy.context.active_object
    singularity.data.materials.append(mat_nebula_glow)
    
    setup_lighting_and_cam((10, -12, 10), (60, 0, 40), light_energy=1800.0)
    save_and_render("celestial_void_obelisk")

if __name__ == "__main__":
    build_monumental_watchtower()
    build_ancient_dolmen_shrine()
    build_volcanic_skull_brazier()
    build_celestial_void_obelisk()
    print("\n[SUCCESS] All 4 Massive World Expansion original 3D asset families generated!")
