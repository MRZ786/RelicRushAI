# RELIC RUSH — MASSIVE OPEN-WORLD ARCHITECTURE AND LAYOUT SPECIFICATION
**Version:** Massive World Expansion Campaign Candidate 2.0  
**Overall Canvas:** 15,000 × 15,000 studs across 5 distinct 5,000 × 5,000 stud regions  
**Target Server:** 20 Concurrent Players  
**Pre-Baked Elements:** 1,591 meaningful structural and environmental parts in `assets/world/RelicRushWorld.rbxmx`  
**Original 3D Asset Families:** 15 Custom Blender Families (.obj, .blend, and Cycles .png renders)  
**Coordinate Origin:** Forgotten Market Hub Plaza Center `(0, 10, 0)`

---

## 1. MASTER 15,000 × 15,000 REGIONAL SPATIAL LAYOUT

```
                                  [ REGION 3: THE ASHEN DOMAIN ]
                                  Center: (0, 10, -5000) | 5,000 x 5,000 studs
                                  X: [-2500, 2500] | Z: [-7500, -2500]
                                  Avenue of Caesars, Curia Basilica, Scorched Crucible PvP,
                                  Praetorian Aqueduct, Catacombs of Praetors Dungeon
                                                 ▲
                                                 │
                                                 │ Northern Imperial Highway (40 studs wide)
                                                 │
                                                 ▼
[ REGION 2: THE FORGOTTEN WILDS ] ◄────────────── [ REGION 1: FORGOTTEN MARKET HUB ] ──────────────► [ REGION 5: THE CELESTIAL RIFT ]
Center: (-5000, 10, 0) | 5,000 x 5,000 studs       Center: (0, 10, 0) | 5,000 x 5,000 studs             Center: (5000, 250, 0) | 5,000 x 5,000 studs
X: [-7500, -2500] | Z: [-2500, 2500]               X: [-2500, 2500] | Z: [-2500, 2500]                  X: [2500, 7500] | Z: [-2500, 2500] (Y=250)
Emerald Highway (40 studs wide)                    Central Plaza, Guildhalls, Clocktower,               Grand Starlight Ascent Bridge, 7 Floating
120 Wispwood Trees, Elder Ironwood Heart Tree,     20 Player Sanctum Estates (4x5 Grid),                Archipelagos, Void Crown Spire, Crown Altar,
Shifting Sands Dolmen, Druid Crypt Dungeon         Hollow Crown Monument, 4 Gateway Portals             Astral Sanctum of the Void Dungeon
                                                 ▲
                                                 │
                                                 │ Southern Bastion Causeway (40 studs wide)
                                                 │
                                                 ▼
                                  [ REGION 4: THE SUNKEN VAULT ]
                                  Center: (0, 10, 5000) | 5,000 x 5,000 studs
                                  X: [-2500, 2500] | Z: [2500, 7500]
                                  Flooded Moat, Drawbridge, 36 Curtain Walls,
                                  8 Watchtowers, Sentry Corridor, Geared Blast Door,
                                  Octagonal Vault Citadel, 3 Extraction Pads
```

---

## 2. DETAILED REGIONAL DIRECTORY

### Region 1: The Forgotten Market (Capital Hub & Grand Sanctum District)
- **Center:** `(0, 10, 0)`
- **Footprint:** `[-2500, 2500]` X, `[-2500, 2500]` Z (5,000 × 5,000 studs total)
- **Spawn Location:** `MarketSpawn` at `(0, 12, 52)` (Inside South Gateway)
- **Total Elements:** 350+ hand-crafted elements
- **Key Landmarks:**
  - **The Grand Plaza:** Radial paving with outer cobblestone curb (`radius = 140`), mid marble ring (`radius = 90`), and inner slate ring (`radius = 50`).
  - **Central Monument & Signature Relic:** Reflecting pool basin at `(0, 10.8, 0)` with granite rim, turquoise water, and obsidian pedestal displaying **The Hollow Crown** (`CrownCircletBase` at `(0, 17.8, 0)`).
  - **4 Cardinal Obelisks:** At `(±18, 16, ±18)` with floating blue fire braziers.
  - **Town Square Clocktower:** `ClockTowerBase` at `(28, 10.8, 42)` (4-tier stone/timber tower, 52 studs tall, bell spire).
  - **5 Two-Story Half-Timbered Guildhalls:**
    - Antiquities Exchange (`BobGuildFloor` at `(55, 10.5, 0)`): appraisal counter, display cases, chandelier.
    - Scholarly Conclave (`CorvusGuildFloor` at `(-55, 10.5, 0)`): grimoire library, runic study.
    - Vance Shadow's Infiltration Lodge (`VanceGuildFloor` at `(-45, 10.5, -45)`): tactical armory, map table.
    - Ironwright Forge (`ForgeGuildFloor` at `(45, 10.5, -45)`): anvil, quench trough, 26-stud stone chimney.
    - Cartographer's Guild: navigation charts, surveyor instruments.
  - **12 Luxury Artisan Market Stalls:** Stretched cloth awnings, timber counters, crate clusters.
  - **Player Base District (20 Sanctums Grid Layout):**
    - **Avenue Infrastructure:** Grand Sanctum Boulevard (48 studs wide × 1,600 studs long at `Z = 0`), and 5 Cross-Avenues at `X = 600, 950, 1300, 1650, 2000`.
    - **Sanctum Sizing:** 60×60 studs usable base plot (`BASE_PLOT_HALF_SIZE = 30`) with stone corner boundary posts.
    - **Clamped Sightlines:** Plot signboards clamped to `MaxDistance = 45`, `AlwaysOnTop = false`, preventing skyline clutter and overlapping labels across the server.
    - **20 Sanctum Plot Coordinates (4 Rows × 5 Columns):**
      - Row 1 (`Z = 600`): Plots 1–5 at `X = 600, 950, 1300, 1650, 2000`
      - Row 2 (`Z = 200`): Plots 6–10 at `X = 600, 950, 1300, 1650, 2000`
      - Row 3 (`Z = -200`): Plots 11–15 at `X = 600, 950, 1300, 1650, 2000`
      - Row 4 (`Z = -600`): Plots 16–20 at `X = 600, 950, 1300, 1650, 2000`
    - **Each Estate Features:**
      - Base plot slate slab (60 × 1.2 × 60)
      - 4 Carved rune boundary corner posts (cyan neon)
      - Plot signpost
      - Tier 1 starter shelter (4 heavy timber posts, pitched roof, lantern)
      - Workshop bench
      - Marble display plinth with gold trim and starter Scavenger Compass
      - Sanctum storage chest

---

### Region 2: The Forgotten Wilds
- **Center:** `(-5000, 10, 0)`
- **Footprint:** `[-7500, -2500]` X, `[-2500, 2500]` Z (5,000 × 5,000 studs)
- **Arrival Point:** `(-3000, 12, 0)` via Emerald Highway
- **Total Elements:** 360+ hand-crafted elements
- **Key Landmarks:**
  - **The Emerald Highway:** 40 studs wide paved route from X = -2500 to X = -2800 with mossy milestones, curbs, and stone bridge arches.
  - **The Whispering Hollow & Elder Ironwood Heart Tree:** Center `(-5000, 34, 0)`, 52-stud tall hollow trunk (`IronwoodTrunk`), 8 buttress roots, double-layered 64-stud canopy, and spore motes.
  - **Druidic Standing Stones:** 8 megalithic standing stones in a 32-stud radius circle around the Elder Tree with glowing emerald rune bands.
  - **Megalithic Dolmen Shrine of Shifting Sands:** `(-5000, 10, -1800)` with 2-tier sandstone plinth, 8 fluted columns, and Hourglass Altar.
  - **Sunken Amphitheater Ruins:** `(-5000, 10, 1800)` with 4 tiers of semicircular stone seating and tranquil reflecting pool.
  - **Forest Biome Elements:**
    - 120 Ancient Wispwood Trees across the 5,000-stud forest expanse
    - 48 Weathered Mossy Granite Boulders
    - 24 Hollow Fallen Logs with shelf fungi
    - 36 Bioluminescent Mushroom Glades
    - 18 Megalithic Dolmen Shrines
  - **NPC Warden:** Keeper Sylva at `(-4985, 10, 5)`.
  - **Dungeon 1 — Sunken Crypt of the Druids:**
    - **Entrance:** Megalithic Crypt Arch at `(-6200, 10, -500)` with glowing emerald veil.
    - **Environmental Puzzle:** 4 Elemental Rune Pillars (Earth, Water, Flora, Sun).
    - **Boss Guardian:** Ancient Ironwood Golem (250 HP, 3-minute respawn cycle).
    - **Treasure Vault:** Ancient Druid Sarcophagus at `(-6200, 13.5, -700)`. Rewards $150 Cash, 40 Shards, and Shadow Talisman relic.

---

### Region 3: The Ashen Domain (Empire District)
- **Center:** `(0, 10, -5000)`
- **Footprint:** `[-2500, 2500]` X, `[-7500, -2500]` Z (5,000 × 5,000 studs)
- **Arrival Point:** `(0, 12, -3000)` via Northern Imperial Highway
- **Total Elements:** 330+ hand-crafted elements
- **Key Landmarks:**
  - **Northern Imperial Highway:** 40 studs wide paved highway with basalt curbs and triumphal imperial gatehouse of Aurelius.
  - **Avenue of the Caesars:** 40 studs wide × 2,500 studs long flagstone boulevard (`AvenuePavement` at `(0, 11.2, -5000)`) flanked by polished marble curbs.
  - **12 Monumental Caesar Imperial Statues:** Flanking the Avenue of the Caesars on 6-stud marble plinths.
  - **Senatorial Curia Basilica:** At Z = -4000 with stepped marble podium, 8 Corinthian portico columns, and gold pediment.
  - **1,500-Stud Roman Aqueduct:** Arched aqueduct conduit with 16 masonry piers spanning volcanic ravines.
  - **Praetorian Garrison Barracks:** At `(52, 12, -4180)` with war banners and armory.
  - **NPC Commander:** Tribune Aurelius.
  - **Contested PvP Arena — The Scorched Crucible:**
    - **Center:** `(0, 12, -4500)`
    - **Bounds:** `X: [-80, 80], Z: [-4580, -4420], Y: [0, 60]`
    - **Features:** Sunken basalt arena floor `(160 × 0.6 × 160 studs)`, active magma rift, 8 corner volcanic skull braziers with roaring flames.
    - **Combat Rules:** Non-destructive PvP knockout (0 relic loss, 0 backpack loss, 0 wallet loss). The victor is awarded a $50 honor cash reward and 10 shards. Outside this arena, PvP combat is strictly disabled.
  - **Dungeon 2 — Catacombs of the Praetors:**
    - **Entrance:** Portal at `(-1200, 10, -5200)`.
    - **Environmental Puzzle:** 3 Timed Bronze Pressure Plates. All three must be depressed within an 18-second coordination window.
    - **Boss Guardian:** Praetorian Centurion Shade (350 HP, crimson crest, gilded praetor shield, 3-minute respawn cycle).
    - **Treasure Vault:** Imperial Praetor Sarcophagus at `(-1200, 14, -5400)`. Rewards $220 Cash, 65 Shards, and Merchant's Eye relic.

---

### Region 4: The Sunken Vault (Obsidian Outpost)
- **Center:** `(0, 10, 5000)`
- **Footprint:** `[-2500, 2500]` X, `[2500, 7500]` Z (5,000 × 5,000 studs)
- **Arrival Point:** `(0, 14, 3000)` via Southern Bastion Causeway
- **Total Elements:** 270+ hand-crafted elements
- **Key Landmarks:**
  - **Southern Bastion Causeway & Drawbridge:** 40 studs wide paved causeway spanning across the flooded moat with a 36-stud heavy timber drawbridge deck.
  - **Fortified Curtain Walls:** 36 segments of ashlar curtain wall with sloped talus foundation plinths and machicolation corbels.
  - **Twin Gatehouse Bastions:** 4-tier fortress towers with crenellations and portcullis blast doors.
  - **8 Monumental 4-Tier Watchtowers:** Distributed along perimeter curtain walls and bastions.
  - **Courtyard Infiltration Zone:** 16 spiked abatis barriers, sandbag revetments, chest-high stone barricades.
  - **Barrel-Vaulted Sentry Corridor:** 12 ribbed groined vault arches and laser tripwire emitters.
  - **Security Mainframe Control Room:** Phosphor green CRT terminal and server racks.
  - **The Inner Citadel & Vault:**
    - **Circular Geared Blast Door:** 18×18 stud circular steel door with 12 interlocking radial teeth and lock wheel.
    - **Grand Octagonal Vault:** 8 fluted obsidian columns, sacred geometry floor mosaic, and central Obsidian Chalice dais.
  - **3 Emergency Extraction Landing Pads:** Alpha (West), Beta (East), and Gamma (South) docks with flare beacons.

---

### Region 5: The Celestial Rift (Hollow Realm)
- **Center:** `(5000, 250, 0)` (Elevated Void Dimension at Y = 250)
- **Footprint:** `[2500, 7500]` X, `[-2500, 2500]` Z (5,000 × 5,000 studs)
- **Arrival Point:** `(3200, 252, 0)` via Grand Starlight Ascent Bridge
- **Total Elements:** 280+ hand-crafted elements
- **Key Landmarks:**
  - **Grand Starlight Ascent Bridge:** 30 studs wide forcefield bridge spanning from `(2200, 10, 0)` to `(3200, 250, 0)` with 25 celestial violet light steps and starlight pylons.
  - **7 Floating Cosmic Archipelagos (Obsidian Islands):**
    1. Arrival Island (`ArrivalIsland` at `(3200, 245, 0)`): Octagonal obsidian slab with void return portal, void monoliths.
    2. Nexus Gateway Island (`(3900, 252, 0)`): Glowing core crystal.
    3. Crystal Steppes Island (`(4400, 258, -400)`).
    4. Singularity Isle (`(4400, 258, 400)`).
    5. The Whispering Shards (`(5000, 262, -600)`).
    6. Crown Spire Apex Island (`(5000, 268, 0)`): Monumental Void Crown Spire (`CrownSpireBase` at `(5000, 278, 0)`), 60-stud spire needle, 2 concentric floating orbital rings (24-stud and 16-stud diameter), and violet beacon light.
    7. Astral Sanctum Isle (`(6500, 290, 800)`).
  - **12 Celestial Light Bridges:** Connecting all archipelagos with translucent violet lattice and guardrails.
  - **Altar of The Hollow Crown:** Ethereal levitating dais at `(5000, 277, 40)`.
  - **Cosmic Dimension Elements:**
    - 96 Floating Void Crystal Clusters
    - 24 Levitating Celestial Void Obelisks
    - 32 Astral Light Beacon Braziers
  - **Dungeon 3 — Astral Sanctum of the Void:**
    - **Entrance:** Void Rift Portal at `(6500, 290, 800)`.
    - **Environmental Puzzle:** 4 Levitating Astral Light Plates.
    - **Boss Guardian:** Void Singularity Sentinel (450 HP, 3-minute respawn cycle).
    - **Treasure Vault:** Singularity Reliquary at `(6500, 312, 630)`. Rewards $350 Cash, 120 Shards, and The Hollow Crown relic.

---

## 3. SUMMARY OF ELEMENT COUNTS BY REGION

| Region ID | Region Name | Stud Dimensions | Center Position | Pre-Baked Elements |
|:---:|:---|:---:|:---:|:---:|
| 1 | Forgotten Market & Grand Sanctum | 5,000 × 5,000 | `(0, 10, 0)` | 350+ |
| 2 | Forgotten Wilds | 5,000 × 5,000 | `(-5000, 10, 0)` | 360+ |
| 3 | Ashen Domain (Empire District) | 5,000 × 5,000 | `(0, 10, -5000)` | 330+ |
| 4 | Sunken Vault (Obsidian Outpost) | 5,000 × 5,000 | `(0, 10, 5000)` | 270+ |
| 5 | Celestial Rift (Hollow Realm) | 5,000 × 5,000 | `(5000, 250, 0)` | 280+ |
| **TOTAL** | **Entire Universe Canvas** | **15,000 × 15,000** | — | **1,591 Elements** |

---

## 4. 15 ORIGINAL 3D ASSET FAMILIES (100% CUSTOM BLENDER ASSETS)

1. `relic_hollow_crown` (.obj, .blend, render.png) — Gilded spiked sovereign circlet with cabochon rubies.
2. `archway_gothic` (.obj, .blend, render.png) — Pointed archway with clustered colonnettes and foliated spandrels.
3. `druidic_monolith` (.obj, .blend, render.png) — Weathered megalithic menhir with chiseled luminescent runes.
4. `crown_spire` (.obj, .blend, render.png) — Obsidian needle monument with dual concentric orbital rings.
5. `ancient_wispwood_tree` (.obj, .blend, render.png) — Gnarled ancient ironwood trunk with buttress roots and hanging wisp pods.
6. `merchant_stall_luxury` (.obj, .blend, render.png) — Timber bazaar stall with scalloped velvet canopy and display crates.
7. `caesar_imperial_statue` (.obj, .blend, render.png) — Heroic Roman imperator in cuirass and paludamentum cloak on marble pedestal.
8. `obsidian_vault_door` (.obj, .blend, render.png) — Heavy blast door with circular locking ring and reinforced rivet bands.
9. `dungeon_modular_door` (.obj, .blend, render.png) — Vaulted dungeon doorway with wrought iron portcullis grill.
10. `puzzle_rune_pillar` (.obj, .blend, render.png) — Hexagonal plinth pillar with glowing elemental rune face.
11. `guardian_statue_golem` (.obj, .blend, render.png) — Ancient sentinel colossus in vigilant stance with glowing optic lenses.
12. `monumental_watchtower` (.obj, .blend, render.png) — 4-tier fortress watchtower with corbel deck, pitched roof, and beacon fire.
13. `ancient_dolmen_shrine` (.obj, .blend, render.png) — Megalithic Celtic dolmen altar with twin upright portal stones and capstone.
14. `volcanic_skull_brazier` (.obj, .blend, render.png) — Flared basalt brazier with demon horns and roaring magma core.
15. `celestial_void_obelisk` (.obj, .blend, render.png) — Levitating astral monolith with orbiting crystal shards and ascension motes.
