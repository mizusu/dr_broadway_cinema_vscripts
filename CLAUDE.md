# dr_skullgirls_cinema — TF2 deathrun map

A TF2 deathrun map with a cinema theme. The map is edited in Hammer++ and versioned in this repo, together with its VScript (Squirrel) code.

The owner dislikes working in Hammer. Do as much as possible by editing the .vmf text and in VScript, so that Hammer++ is only needed to look over the result and compile.

## Repo layout

- `dr_skullgirls_cinema.vmf` is the map source and the single source of truth. It used to be kept in Google Drive; this repo copy now replaces that.
- `create_cbs.nut` is the Christian Brutal Sniper boss: a `base_boss` NPC with a theme, death sound and attacks. It is already under way.
- `create_following_bot.nut` is a generic `base_boss` NPC that follows players, from the same code base as CBS.
- `player_utils.nut`, `deep_print_table.nut` and `showevents.nut` are helpers and debug tools.
- `hello_world.nut` is run by the map's `helloWorldLogicScript`. It is an early multi-kill announcer prototype: it counts every player death within 2 seconds (not yet per BLU attacker) and alternates `sound_blu_multikill1`/`2`. It also holds debug helpers and the 2-second spawn uber.
- `patrons_damage_monitor.nut` is included by both bot scripts. The original was lost, so it is currently a stub that defines an empty `::recordPatronDamage(params)`, the only thing the scripts use from it (called in `create_following_bot.nut`'s `OnScriptHook_OnTakeDamage`). The real logic, tracking damage to the ambient "patron" NPCs that trigger the CBS boss, is to be written together with the CBS trigger.
- `.vscode/launch.json` holds the VS Code VScript debugger config (attach to localhost, Squirrel3).

## Rules for editing the .vmf

- Commit before each editing session; git history replaces manual `.bak` copies.
- The owner must close the map in Hammer++ before Claude edits the file, or Hammer will overwrite the changes.
- Keep the CRLF line endings and tab indentation the file already uses. `.gitattributes` stops git from converting them, so edits must write CRLF too.
- When adding things, give them `id`s above the current maximum (entities, solids and sides). The file already had 385 repeated ids before Claude edited it, probably because Hammer numbers object types separately, so don't try to "fix" those.
- Leave the Hammer++ sections (`palette_plus`, `colorcorrection_plus`, `light_plus`, `bgimages_plus`) and the existing visgroups as they are.
- Entity outputs in `connections` use the 0x1B (ESC) character as a separator, not commas.
- The file is about 14 MB (around 615k lines). Search it with grep or read it in parts; don't read it whole.
- After editing, ask the owner to open the map in Hammer++, check it visually, then compile and playtest. CompilePal is recommended for compiling and for packing custom content.

## Intended route (owner's design)

Heights (z) and areas were measured from the .vmf. Ones marked "(guess)" haven't been confirmed by the owner.

1. **Spawn outside**, at ground level on the north side (z ≈ 0, `info_player_teamspawn` at 192 1536 16).
2. **Enter the cinema** into a hallway on the first floor. The west wing has **two identical theaters** (one copy-pasted from the other), with sunken stepped floors at z 320–770 and a corridor between them. The **north theater** (screen at y ≈ −2,080) and **south theater** (screen at y ≈ −5,450) are unnamed. **One is the safe theater RED passes through; the other is the trap room**: a trap funnels RED into it and they die. Which one is which is still open. Claude recommends north = safe, south = trap, because most of the existing pushes point south (yaw 268). The 8 `theater1_trigger_push` triggers are **leftover test entities** for that trap. They now start disabled (speed 1000), so the route is walkable. The trap should send `Enable` to `theater1_trigger_push` for a few seconds, then `Disable`.
3. **Exit the safe theater up to the second floor** (z ≈ 720–790). The second floor is the level of the elevator lobby and the BLU balcony, and RED leaves the safe theater into a hallway on it. (The floors at z ≈ 1,056–1,360 are *not* the trap theater.)
4. **Elevator lobby** (z ≈ 720–790, near x 400, y −4,250/−4,570). `elevator1`/`elevator2` ride from z 788 up to z 3,824, about 3,000 units.
5. **Upper floor, middle of the tower** (z ≈ 3,124–3,968, spanning y −8,176 to −848). A **grand opera/stage-style theater**: players cross the main stage, then go down the middle of the (empty) audience seating. The stepped floors at z 3,124–3,584 to the south are likely the seating (guess).
6. **Back to the elevator-arrival floor, heading left now**, to the **opera-level elevator (not made yet)** that goes up to:
7. **Hotel/residential floor** (z ≈ 4,864, ceiling ≈ 5,024–5,056, x −2,304..1,376, y −8,320..−5,344). Its windows look out at the skyline to show how high up players are.
8. **Teleporter = finish.** `teleport_origin1` (−2160 −7344 4928, the west end of the hotel floor) sends players to `teleport_destination1` (192 1664 1888), the end area. That's a **crude temporary tower** behind and above the spawn (floors at z ≈ 1,856–2,144), still to be rebuilt.

**Trap and BLU booth plan:** see [TRAP_PLAN.md](TRAP_PLAN.md) (a draft awaiting the owner's answers).

**BLU (activator):** there are **no traps, no BLU path and no trap buttons yet**. That's the biggest missing piece. The design calls for an exclusive BLU path that RED can't enter or interfere with. The only BLU area so far is a **spawn balcony** on the cinema's front at about elevator-lobby height. It overlooks the outdoor RED spawn so each team can see the other, and RED can check whether BLU is AFK before rushing in. Location (confirmed): floor z 720, x −800..960, y −1,536..−832, behind the glass at the front facade. A short staircase beside the glass (x ≈ −770..−590) leads out to an outdoor ledge (z 656). It now has 4 BLU spawns. **It is not sealed off:** the balcony is the front of a U-shaped gallery around the atrium, and the gallery runs into the second-floor hallway and elevator lobby that RED uses. So BLU can walk to the elevators and RED can walk up to the balcony. The seal has to go at the balcony itself (suggestion: a glass partition across x −800..960 at y ≈ −1,500, so the teams can still see each other). The map has no team filters (`filter_activator_tfteam`) or `func_respawnroomvisualizer` yet.

Other structures: the tower crown goes up to z 6,592 above the central block; there's a pit below ground (z −768) near the monorail and an unknown area at z 1,824 far east (x 4,224..5,440).

## Current state

- About 1,330 world brushes, 1,056 prop_static, about 480 light entities, a single env_cubemap.
- Done: cinema building, skybox (`sky_night_01`, sky_camera plus an `instances/sky_camera` instance), and the ambience.
- Two elevators (`elevator1`, `elevator2`): func_tracktrain + path_track + func_door doors.
- Theater has `theater1_trigger_push` triggers. Teleporter `teleport_origin1` → `teleport_destination1`, with a portal effect.
- "MS3 Boss" monorail: `ms3_mono_train1` on `ms3_mono1_track1..3` (currently hidden in Hammer).
- Script: a `logic_script` named `helloWorldLogicScript` running `hello_world.nut`. The CBS and bot scripts are not yet wired into the map.
- Multi-kill announcer: ambient_generic entities `sound_blu_doublekill`, `_triplekill`, `_overkill`, `_killtacular`, `_multikill1`, `_multikill2` (4 stacked copies each, using `skullgirls/*.mp3`), triggered only by test buttons.
- Test entities: `bison_test` (env_explosion), `bison_test_point_hurt` (3 point_hurt), `test_button`, `test_button2`.

## Known bugs to fix first

1. ~~Spawns and arena logic~~ added (not yet playtested): 34 RED spawns on the plaza (the original at 192 1536 16 plus a 3×11 grid at x −288..672, y 1184..1376, 96 apart, facing south), 4 BLU spawns on the balcony (x ±128, y −1024/−1152, z 736, facing north), and `tf_logic_arena` named `arena_logic` (CapEnableDelay 60) at 64 1024 64.
2. Outputs pointing to entities that do not exist:
   - A theater func_button targets `theater1_movelinear` (does not exist).
   - `test_button` / `test_button2` target `ms3_mono1` (the train is actually named `ms3_mono_train1`). **Leave it alone:** the MS3 monorail boss fight may be scrapped, and the owner won't touch it until the map is finished.
3. ~~Elevator bugs~~ fixed in commit 0def5a9: elevator1's top stop now stops elevator1, both door triggers are parented to their own car, and the orphan `elevator1_track_floor2` was removed. Not yet playtested.
4. The `trigger_hurt` (damage 200, around 648 -640 368) starts disabled and nothing enables it. It is an abandoned, unfinished trap. Leave it unless the owner revisits it.
5. Custom content must be packed into the BSP: `skullgirls/*` sounds, textures in the CUSTOMDEV and MYTEXTURES folders, and a few non-TF2 models. This content lives outside the repo (Google Drive).

## Planned features (VScript)

- Multi-kill announcer: hook `player_death`, count kills per BLU attacker within a short time window, play the matching sound once (replacing the stacked ambient_generics and test buttons). Fighting-game announcer lines too.
- Christian Brutal Sniper boss (started in `create_cbs.nut`): ambient NPCs; if they get killed, the boss spawns and chases players (base_boss / NextBot + navmesh), with announcer, voice lines and music.
- Holiday props: show a Halloween or Christmas prop set based on date / TF2 holiday checks.
- Dynamic clocks, plus movie event text and banners that change with the time of day (point_worldtext, pre-packed material/skin swaps).
- Not possible in VScript: fetching posters/titles from the internet (sandboxed, no HTTP). That would need a SourceMod plugin, and posters could only switch between pre-packed images.
- Traps: keep Hammer work to named placeholders (brush, button, marker); put the behavior in Squirrel.

## Suggested order

Fix the theater button target → add spawns and arena logic → compile and test → wire the scripts into the map → multi-kill script → first traps.
