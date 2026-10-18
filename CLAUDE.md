# dr_skullgirls_cinema — TF2 deathrun map

A TF2 deathrun map with a cinema theme. The map is edited in Hammer++ and versioned in this repo, together with its VScript (Squirrel) code.

**Read [VISION.md](VISION.md) before design work.** It covers the owner's intent: a grand 1920s–30s movie palace (Radio City's Grand Foyer is the first room), dark warm lighting, city views, Skullgirls music by random chance (never looping), and Halo/CvS2 announcers. The owner's reference images and sounds are in `user-ideas/` (about 240 MB, sorted by part of the route). Look at only the files a task needs.

The owner dislikes working in Hammer. Do as much as possible by editing the .vmf text and in VScript, so that Hammer++ is only needed to look over the result and compile.

## Repo layout

- `dr_skullgirls_cinema.vmf` is the map source and the single source of truth. It used to be kept in Google Drive; this repo copy now replaces that.
- `create_cbs.nut` is the Christian Brutal Sniper boss. The owner says it is `create_following_bot.nut` with the CBS model (`models/christian_brutal_sniper/sniper.mdl`), the `cbs_theme` music on spawn and Sniper death lines. The owner's melee attempt (`DoMeleeAttack`) probably never dealt damage, and it has no swing animation.
- `create_following_bot.nut` is **the valuable piece** (the owner's words): a `base_boss` NextBot that pathfinds over the nav mesh, gets around obstacles and follows a player. It has its own health tracking and ragdolls on death. It uses the HL2 `humans/group02/female_04` model and is the base for the ambient "patron" NPCs. It still spawns at the host's crosshair (`BotCreate`, from the console) and uses `GetListenServerHost()`, which returns nothing on a dedicated server.
- `player_utils.nut`, `deep_print_table.nut` and `showevents.nut` are helpers and debug tools.
- `hello_world.nut` is run by the map's `helloWorldLogicScript`. It is an early multi-kill announcer prototype: it counts every player death within 2 seconds (not yet per BLU attacker) and alternates `sound_blu_multikill1`/`2`. It also holds debug helpers and the 2-second spawn uber.
- `patrons_damage_monitor.nut` is included by both bot scripts. The original was lost, so it is currently a stub that defines an empty `::recordPatronDamage(params)`, the only thing the scripts use from it (called in `create_following_bot.nut`'s `OnScriptHook_OnTakeDamage`). The real logic, tracking damage to the ambient "patron" NPCs that trigger the CBS boss, is to be written together with the CBS trigger.
  The owner checked the lost original (2026-10-18): it only built a table of the lobby's player IDs and never tracked damage, so it isn't worth recovering. Write the trigger from scratch.
- `facade.nut` runs the facade clock (real time) and the random marquee title. It is run by `facade_logic` and packed by `compile.ps1`.
- `elevators.nut` runs the two elevators (see Current state). It is run by the `elevator_logic` logic_script and packed into the .bsp by `compile.ps1`.
- `compile.ps1` compiles the map from the command line (`powershell -ExecutionPolicy Bypass -File .\compile.ps1`, add `-Final` for release lighting). It uses TF2's 32-bit `bin\` tools (the `bin\x64` ones fail without MaterialSystem.dll), works on a copy in `build/`, packs the scripts with bspzip and copies the .bsp to `tf\maps`. TF2 is at `D:\SteamLibrary\steamapps\common\Team Fortress 2`. It doesn't pack custom content, build cubemaps or a nav mesh; CompilePal (`C:\Tools\Compile.Pal.029`) does those.
- `.vscode/launch.json` holds the VS Code VScript debugger config (attach to localhost, Squirrel3).

## Rules for editing the .vmf

- Commit before each editing session; git history replaces manual `.bak` copies.
- The owner must close the map in Hammer++ before Claude edits the file, or Hammer will overwrite the changes.
- Keep the CRLF line endings and tab indentation the file already uses. `.gitattributes` stops git from converting them, so edits must write CRLF too.
- When adding things, give them `id`s above the current maximum (entities, solids and sides). The file already had 385 repeated ids before Claude edited it, probably because Hammer numbers object types separately, so don't try to "fix" those.
- Leave the Hammer++ sections (`palette_plus`, `colorcorrection_plus`, `light_plus`, `bgimages_plus`) and the existing visgroups as they are.
- Entity outputs in `connections` use the 0x1B (ESC) character as a separator, not commas.
- Don't use Git Bash's `sed -i` on the .vmf: it silently turns every CRLF into LF. Edit it with Python in binary mode.
- Point entities must sit in open space. One inside a brush or the void makes vbsp report a leak.
- The file is about 14 MB (around 615k lines). Search it with grep or read it in parts; don't read it whole.
- After editing, ask the owner to open the map in Hammer++, check it visually, then compile and playtest. CompilePal is recommended for compiling and for packing custom content.

## Intended route (owner's design)

Heights (z) and areas were measured from the .vmf. Ones marked "(guess)" haven't been confirmed by the owner.

1. **Spawn outside**, on the closed-off street in front of the cinema (z 0). See "Premiere Night forecourt" below.
2. **Enter the cinema** into a hallway on the first floor. The west wing has **two identical theaters** (one copy-pasted from the other), with sunken stepped floors at z 320–770 and a corridor between them. The **north theater** (screen at y ≈ −2,080) and **south theater** (screen at y ≈ −5,450) are unnamed. **The south theater is the safe one** RED passes through. **The north theater is the trap room**: a trap funnels RED into it and they die (owner's decision). Most of the existing pushes point south (yaw 268), and two of them (y −4,320 and −4,592) sit inside the south theater, so they need re-aiming toward the north theater when the trap is built. The 8 `theater1_trigger_push` triggers are **leftover test entities** for that trap. They now start disabled (speed 1000), so the route is walkable. The trap should send `Enable` to `theater1_trigger_push` for a few seconds, then `Disable`.
3. **Exit the safe theater up to the second floor** (z ≈ 720–790). The second floor is the level of the elevator lobby and the BLU balcony, and RED leaves the safe theater into a hallway on it. (The floors at z ≈ 1,056–1,360 are *not* the trap theater.)
4. **Elevator lobby** (z ≈ 720–790, near x 400, y −4,250/−4,570). `elevator1`/`elevator2` ride from the lobby (floor z 720) up to the top floor (z 3,703), about 3,000 units.
5. **Upper floor, middle of the tower** (z ≈ 3,124–3,968, spanning y −8,176 to −848). A **grand opera/stage-style theater**: players cross the main stage, then go down the middle of the (empty) audience seating. The stepped floors at z 3,124–3,584 to the south are likely the seating (guess).
6. **Back to the elevator-arrival floor, heading left now**, to the **opera-level elevator (not made yet)** that goes up to:
7. **Hotel/residential floor** (z ≈ 4,864, ceiling ≈ 5,024–5,056, x −2,304..1,376, y −8,320..−5,344). Its windows look out at the skyline to show how high up players are.
8. **Teleporter = finish.** `teleport_origin1` (−2160 −7344 4928, the west end of the hotel floor) sends players to `teleport_destination1` (192 1664 1888), the end area. That's a **crude temporary tower** behind and above the spawn (floors at z ≈ 1,856–2,144), still to be rebuilt.

**Trap and BLU booth plan:** see [TRAP_PLAN.md](TRAP_PLAN.md) (a draft awaiting the owner's answers).

**BLU (activator):** there are **no traps, no BLU path and no trap buttons yet**. That's the biggest missing piece. The design calls for an exclusive BLU path that RED can't enter or interfere with. The only BLU area so far is a **spawn balcony** on the cinema's front at about elevator-lobby height. It overlooks the outdoor RED spawn so each team can see the other, and RED can check whether BLU is AFK before rushing in. Location (confirmed): floor z 720, x −800..960, y −1,536..−832, behind the glass at the front facade. A short staircase beside the glass (x ≈ −770..−590) leads out to an outdoor ledge (z 656). Its 4 BLU spawns stand on a VIP dais behind the glass (see the forecourt section). **It is not sealed off:** the balcony is the front of a U-shaped gallery around the atrium, and the gallery runs into the second-floor hallway and elevator lobby that RED uses. So BLU can walk to the elevators and RED can walk up to the balcony. The seal has to go at the balcony itself (suggestion: a glass partition across x −800..960 at y ≈ −1,500, so the teams can still see each other). The map has no team filters (`filter_activator_tfteam`) or `func_respawnroomvisualizer` yet.

Other structures: the tower crown goes up to z 6,592 above the central block; there's an unknown area at z 1,824 far east (x 4,224..5,440).

## Premiere Night forecourt (outdoor spawn area)

Built 2026-10-18 at the owner's request, with creative liberty (no references for this area), and revised (v2) after the first look. The owner's requirements: RED sees the whole tower while waiting, RED can tell if BLU is AFK, a small area, and lit like a city at night. The original plan image is [docs/forecourt_plan.png](docs/forecourt_plan.png); v2 is smaller than shown there.

- **Playable area:** x −1,004..1,196 (centered on the facade, x 96), y −400 (the facade) .. 1,950. Bounded by 16-unit `TOOLS/TOOLSPLAYERCLIP` world brushes up to z 3,000, with HL2 jersey barriers (`props_c17/concrete_barrier001a`) just inside them.
- **Ground:** a 2-unit `func_detail` layer (top z 2, all other faces nodraw) over the old floor. Plaza (`MYTEXTURES/STREETFLOOR1`) from the grand stairs to the road. **The road moved 320 north** to y 1,248..1,888 (`CONCRETEFLOOR026A` curbs, `033K` lanes, spanning x −2,752..3,264). Outside the forecourt, the old road strip is covered with sidewalk (`007B`). The 34 RED spawns, the 16 lampposts and one small lamppost moved north 320 with it, so the RED spawns stand on the road lanes (y 1,504..1,856).
- **The road is closed for the premiere:** sawhorse barricades and "road closed" signs inside both ends, parked HL2 cars and a van beyond.
- **Red carpet:** a `func_detail` (`PROPS/CARPETFLOOR008A`, top z 4) centered on the grand stairs (stairs and landings span x −128..416, center x 144). It runs x 16..272, y 470..1,248, lined with `props_mvm/mvm_museum_rope001` velvet ropes.
- **Searchlights (v3):** six, three per side: plaza corners (−860/1,052, 150), outside the boundary (−1,250/1,450, 700) and behind the road (−860/1,052, 2,100). Each is an invisible nodraw `func_rotating` (`searchlight_rot_1..6`, 7–11°/s, some reversed) carrying a 3×-scaled `props_lights/spotlight001a` (`searchlight_lamp_N`) and a `point_spotlight` beam (`searchlight_beam_N`, pitch −60, length 3,000), on a small concrete pedestal. A visible brush on a `func_rotating` showed as a missing-texture box, so keep the rotator nodraw.
- **Street lighting:** every lamppost has a warm sodium `light` at its head (big HL2 lamps 260 brightness, the 4 small `props_sunshine/lamppost001` 110). The stair `groundlight002` props were removed (they floated), but their light entities were kept.
- **BLU stands outside on the canopy ledge**, the owner's outdoor floor in front of the balcony glass (z 656, x −768..896, y −816..−544, 16-unit parapet at the front). The owner's carpeted stairs come down to it from the balcony at x −775..−587 and will lead to the BLU path later. Sight-line traces: the old balcony spawns were invisible from every RED spawn (the canopy hid them), and spawns deeper on the ledge show only heads. At y −592, right behind the parapet, head and chest are visible from all RED spawns. The 4 BLU spawns are at x −384/−128/128/384, y −592, z 664, facing north. A warm light hangs over the ledge, and a `light_spot` on the plaza (100 900 200) aims at it.
- **Facade signage (v2), from a review of the facade against the references:** the facade is two brick pilasters (front y −388, up to z ~1,856) framing a recess (y −772: balcony glass, ledge, canopy), with a flat slab tower above (y −772 to z ~4,200, then one setback to y −900 up to ~6,600). That zone had no signage or focal point, so it now has:
  - a **marquee board** spanning the pilasters (z 1,150–1,450), with `point_worldtext` `marquee_header` ("SKULLGIRLS CINEMA") and `marquee_title`, which `facade.nut` sets to a random "Now Showing" title each round;
  - a **vertical blade sign** projecting from the left pilaster, z 1,150–3,400 (v3: red "CINEMA" letters on both faces, a gold neon outline (`func_brush` with `LIGHTS/WHITE002` tinted by `rendercolor`, the trick for any colored neon), a stepped Art Deco crest with a red neon spire to z 3,920, and chasing bulbs);
  - an **Art Deco clock** on the tower face (center 96, −750, 3,000; backlit `LIGHTS/WHITE002` face since v3, metal frame, dark numerals) whose `func_brush` hands `clock_hand_hour/minute` show the server's real local time (`facade.nut`, `LocalTime`);
  - warm uplights on both pilasters and a spot on the marquee and clock.

  `point_worldtext` facts learned in game: the text is readable from the side its forward vector points *away* from, so text read from +y needs yaw 270, and +x needs yaw 180. It grows from its origin toward the viewer's right, so to center it, shift the origin by half its width toward the viewer's left. The width is about 0.46–0.51 × textsize per character (estimated; `facade.nut` centers the marquee title this way). Still to do on the facade (Hammer work for the owner): ornament, cornices, the tower crown and setbacks.
- **v3 dressing and near lighting (2026-10-18, the owner's feedback on v2):**
  - **Plaza:** four palms (`egypt/palm_tree/palm_tree_medium`) in planters flanking the carpet. Raised planter beds with island plants cut the plaza's four corners. A sidewalk cafe on the west (3 `props_island/island_parasol_table` with `props_sunshine/cafe_chair001`), an HL2 `fountain_01` on the east, benches and trash bins facing the road, a payphone and newspaper frames.
  - **Near light:** small lights in every planter, at the cafe tables, the fountain and six `groundlight002` ground lights. Four press floodlights (3× `props_lights/flood_light_left001` on poles) along the carpet throw `light_spot` pools onto it.
  - **Streets beyond the barriers:** brick storefront walls (z 0–420) with `props_soho/shopwindow001`, awnings, `props_urban/urban_shop_sign01/02` and a warm light per window. They run south of the road outside the forecourt (y 1,060, facing north) and along the north side (y 2,160, facing south). A `props_soho/bus001` is parked east. The shop window, awning and sign orientations are unverified.
  - **Effects (`facade.nut`):** 85 bulb sprites (`chase_a/b/c`) chase around the marquee board (rows above and below) and up the blade sign's street edge. Eight `paparazzi_flash` sprites along the ropes pop at random in bursts of 1–3.
- **v4 (2026-10-18, the owner's feedback on v3):**
  - **Press lights** along the carpet are now `props_lights/spotlight001a` at 2× (the `flood_light_left001` model hung upside down). Searchlight lamps are 2×.
  - **Bulb models:** a static `props_2fort/lightbulb001` sits behind each of the 85 chasing sprites, so the bulbs exist when unlit.
  - **Flank walls** (the plain 672-tall walls beside the cinema, faces at y −688 west and −656 east): brick cladding (`BRICK/BRICKWALL014A`), trim base course, floor band and cornice (`CONCRETE/CONCRETETRIM001A`), brick piers every 256, self-lit upper windows and poster lightboxes per bay.
  - **Storefront rows** rebuilt as 21 separate buildings of random width (384–640), height (320–640) and material (six bricks/plasters). Each has a cornice, sign band and a grid of upper windows, about two thirds lit. Ground-floor shop windows, awnings cycling through `shopawning001..005` (some buildings have none), occasional shop signs, and varied warm lights. Seeded random (1926), so rebuilds are reproducible.
  - **Self-lit window trick:** `CP_MANOR/WINDOW_GLOW01` is `$selfillum`, so it glows with no light entity or edict. Use it for lit windows anywhere.
  - **Grand clock** (Abraj Al Bait reference): a cream marble housing (x −484..676, z 2,420–3,660, 48 out from the tower face) with a stepped Art Deco crown, corner pinnacles, a gold spire and orb to z 4,344. It covers the window grid behind it. Backlit face (R 380), a gold frame, hour ticks, bands and caps in one self-lit `func_brush` (`clock_gold`, `rendercolor` 255 186 70), 12 roman numerals (`clock_num_0..11`), the inscription `clock_inscription`, and the hands `clock_hand_hour/minute` (same names, so `facade.nut` still drives them), plus a spot lighting the housing.
- **Test buttons removed (owner's request, v3):** `test_button`, `test_button2` and the red start button that sat on the plaza (they appeared as cubes on the carpet).
- **Later:** a "motivator" that kills REDs who stay outside after the round starts (for example, the entrance doors close and a `trigger_hurt` or BLU sentries clear the forecourt), once the doors and traps exist.

## Current state

- About 1,330 world brushes, 1,056 prop_static, about 480 light entities, a single env_cubemap.
- Done: cinema building, skybox (`sky_night_01` with a sky_camera; a broken `instances/sky_camera` func_instance, whose file was missing, was removed), and the ambience.
- Two automatic elevators (`elevator1`, `elevator2`, lobby z 720 → top floor z 3,703), run by `elevators.nut`. They have no buttons: a car leaves 5 s after a living RED player steps in (cancelled if it empties), opens at the top, and returns once empty (after 3–10 s). The doors never close on a player: the car waits while anyone is in the doorway and pushes them out after 4 s. As soon as the doorway is clear, a player-clip func_brush (`elevatorN_doorway_clip_bottom|top`, x 288–313, starts disabled) seals it while the doors close, so a griefer is left behind. If the doors still don't close, it reopens them and retries. Each car is a func_movelinear (movedir up, movedistance 2982, speed 550): `Open` rides up and `Close` rides down, and OnFullyOpen/OnFullyClosed call `Elevator_OnArrive(car, floor)`. (It was a func_tracktrain, but that stopped short when reversing into the lobby, so the path_tracks were removed.) Doors: car doors `elevatorN_doorleft/right` (parented), plus landing doors `elevatorN_landing_bottom|top_left|right` in the shaft frames (x 314–318) that close whenever the car is away. The old buttons are now decorative func_brush and the old door triggers were removed. The owner asked about a second pair facing these (2026-10-18), but it's on hold: the lobby (x −64..304) has the building's outer wall on its west side (x −80, with sky windows on the top floor), so new shafts would stick out of the facade or take half the lobby and cut through every floor in between. Revisit after a playtest with real players, looking at it in Hammer together.
- Theater has `theater1_trigger_push` triggers. Teleporter `teleport_origin1` → `teleport_destination1`, with a portal effect.
- **MS3 removed (2026-10-18, owner scrapped it):** the hidden "MS3 Boss" visgroup (a falling concrete-block train, its track, its hitbox, a landing particle, and the sealed marble pit under the plaza). The original Metal Slug 3 "Monoliths" idea and a VScript design for it are kept in [TRAP_PLAN.md](TRAP_PLAN.md).
- Script: a `logic_script` named `helloWorldLogicScript` running `hello_world.nut`. The CBS and bot scripts are not yet wired into the map.
- Multi-kill announcer: ambient_generic entities `sound_blu_doublekill`, `_triplekill`, `_overkill`, `_killtacular`, `_multikill1`, `_multikill2` (4 stacked copies each, using `skullgirls/*.mp3`), triggered only by test buttons.
- Test entities: `bison_test` (env_explosion), `bison_test_point_hurt` (3 point_hurt), `test_button`, `test_button2`.
- **Outdoor cleanup (2026-10-18):** at the owner's request, 270 test leftovers were removed. East of the plaza (x 1,150–6,800) the owner had laid out prop catalogs while browsing models: light fixtures, fences, stairs, skybox models, a skyscraper lineup, industrial and train-yard props, and desk and museum clutter. Also removed: a few stray props, 7 test particle systems outdoors, three brush-built chair prototypes, and the shelf the light catalog hung from. **Kept on purpose, owner to confirm:** a 3×4 grid of hanging bulbs at x 1,344–1,440, y −448..−544, z 592 (probably part of an entrance canopy), 4 pipeline silhouettes at x ≈ 6,860, y ≈ 1,300, and a cargo-ship silhouette at (2,016, 576). The 7 test particle systems in the foyer were removed too, so the map now has no info_particle_system.

## Known bugs to fix first

1. ~~Spawns and arena logic~~ added and working in the first playtest (arena needs a player on each team; test with `bot -team blue`): 34 RED spawns on the plaza (the original at 192 1536 16 plus a 3×11 grid at x −288..672, y 1184..1376, 96 apart, facing south), 4 BLU spawns, since moved onto the VIP dais (see the forecourt section), and `tf_logic_arena` named `arena_logic` (CapEnableDelay 60) at 64 1024 64.
2. Outputs pointing to entities that do not exist:
   - A theater func_button targets `theater1_movelinear` (does not exist).
3. ~~Elevator bugs~~ The first playtest (2026-10-18) found that the buttons could be shot from outside and sent empty cars, and that the open shafts let players fall in. Both are fixed by the automatic elevators above.
4. The `trigger_hurt` (damage 200, around 648 -640 368) starts disabled and nothing enables it. It is an abandoned, unfinished trap. Leave it unless the owner revisits it.
5. Custom content must be packed into the BSP: `skullgirls/*` sounds, textures in the CUSTOMDEV and MYTEXTURES folders, and a few non-TF2 models. This content lives outside the repo (Google Drive).
6. Found in the first compile and playtest (2026-10-18), not fixed yet:
   - Reflective surfaces (road, glass, elevators) showed pink and black, and the map looked over-bright with glowing Scattergun and pistol viewmodels, because cubemaps were never built. 242 env_cubemaps were added (243 in total), at eye height above real floors, checked against the compiled .bsp's point contents. The first 89 came from the light entities. That missed unlit areas (the sunken theater floors, outdoor streets), so the glow stayed in dark rooms, and 153 more were added from a grid search for floor spots with no cubemap within 768 units in line of sight. The 3D skybox room (about x 2336..3392, y 4448..5568, z 0..672) was excluded. TF2's stock `sky_night_01` has mismatched face sizes, so the engine can never build the default cubemap from it. That's why every playable area needs a nearby env_cubemap. **They have to be built after every compile:** `compile.ps1` overwrites the .bsp in `tf\maps`, so after loading a new build the owner types `exec dr_cubemaps` in TF2. That runs the repo's `dr_cubemaps.cfg` (copied into `tf\cfg` by `compile.ps1`): reflections off, `buildcubemaps`, reflections on, reload. The owner keeps TF2 open while working, so don't automate this with `-buildcubemaps` (it needs TF2 closed). Use CompilePal's CUBEMAPS step for releases. `compile.ps1` also installs `dr_test.cfg` as `tf\cfg\dr_skullgirls_cinema.cfg`. TF2 runs that automatically on every local load of the map: `sv_cheats 1`, no waiting for players, no arena queue, and a BLU bot. Keep test-only commands there, not in the map.
   - The `light_environment` was daylight (`_light` 247 237 204 200, `_ambient` 44 44 44 20) under the night skybox. At the owner's request (2026-10-18) it's now moonlight: `_light` 160 180 230 70, `_ambient` 38 46 72 18. Its `SunSpreadAngle` is −10, which is odd but was left alone. There is no env_tonemap_controller. 59 lights are at brightness 1,000–10,000 (theater-wing spots at 10,000, opera hall at 2,500), probably on purpose for the tall rooms. Ask the owner before changing any of these.
   - vbsp says the `sky_night_01` skybox faces weren't compiled at the same size and flags, so it can't build the default cubemap.
   - 5 prop_static use physics-only models and are deleted at compile (`furnituretable001a/002a/003a`, `furniture_chair03a`, `controlroom_chair001a`). They should be prop_dynamic or prop_physics.
   - ~~5 more needed prop_dynamic~~ (`male_01`, `lamppost03a_off_dynamic`, `hwn_spellbook_page`, `hwn_spellbook_incomplete`, `skybox_carosel`). They were test leftovers and were removed in the outdoor cleanup.
   - 14 `hangingbulb` props at y −1120, z ≈ 587 are outside the map.
   - `CUSTOMDEV/DEV_MEASUREGENERIC01RED` (162 faces) isn't installed in TF2.

## Planned features (VScript)

- Multi-kill announcer: hook `player_death`, count kills per BLU attacker within a short time window, play the matching sound once (replacing the stacked ambient_generics and test buttons). Fighting-game announcer lines too.
- Roaming patrons and the Christian Brutal Sniper boss (started in `create_following_bot.nut` and `create_cbs.nut`, base_boss / NextBot + navmesh). The owner's full design is in [VISION.md](VISION.md) under "Patrons and the CBS boss": patrons who flee when hurt, lobby-wide damage tracking, CBS hunting the top damage dealers, then pacifying.
- Holiday props: show a Halloween or Christmas prop set based on date / TF2 holiday checks.
- Dynamic clocks, plus movie event text and banners that change with the time of day (point_worldtext, pre-packed material/skin swaps).
- Not possible in VScript: fetching posters/titles from the internet (sandboxed, no HTTP). That would need a SourceMod plugin, and posters could only switch between pre-packed images.
- Traps: keep Hammer work to named placeholders (brush, button, marker); put the behavior in Squirrel.

## Where we left off (2026-10-18)

- **Waiting on the owner:** in-game screenshots of the forecourt v4 (grand clock housing, flank walls, storefront rows, bulb models, press lights). Fix whatever they show first.
- **Next, before traps:** an entity-data trimming pass (entdata is at 67% of its cap). Generated entities carry default keyvalues; nearby small lights could be merged; the 24 stacked multi-kill `ambient_generic`s go once the announcer script exists.
- **Then the agreed plan:** version 1 ends in the opera hall (the hotel floor is version 2). The first milestone is a vertical slice in the grand foyer: seal the BLU balcony, a BLU booth, the trap framework script, a falling-chandelier trap (`foyer_chandelier_1..4` already exist), round-start/K.O. announcers, and random-chance menu music.
- **Still open:** a "motivator" that kills REDs who stay outside; the 5 furniture props that need prop_dynamic; packing custom content (CompilePal); `hello_world.nut` isn't packed (the map's `helloWorldLogicScript` errors in console until the announcer replaces it).
- **Working setup:** `compile.ps1` → `map dr_skullgirls_cinema` (cheats, no waiting and a BLU bot come from the auto map cfg) → `exec dr_cubemaps`. The owner keeps TF2 open while working.

## Suggested order

Fix the theater button target → add spawns and arena logic → compile and test → wire the scripts into the map → multi-kill script → first traps.
