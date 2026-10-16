# dr_skullgirls_cinema — TF2 deathrun map

A TF2 deathrun map with a cinema theme. The map is edited in Hammer++ and versioned in this repo, together with its VScript (Squirrel) code.

The owner dislikes working in Hammer. Do as much as possible by editing the .vmf text and in VScript, so that Hammer++ is only needed to look over the result and compile.

## Repo layout

- `dr_skullgirls_cinema.vmf` is the map source and the single source of truth. It used to be kept in Google Drive; this repo copy now replaces that.
- `create_cbs.nut` is the Christian Brutal Sniper boss: a `base_boss` NPC with a theme, death sound and attacks. It is already under way.
- `create_following_bot.nut` is a generic `base_boss` NPC that follows players, from the same code base as CBS.
- `player_utils.nut`, `deep_print_table.nut` and `showevents.nut` are helpers and debug tools.
- `hello_world.nut` is run by the map's `helloWorldLogicScript`. It is an early multi-kill announcer prototype: it counts every player death within 2 seconds (not yet per BLU attacker) and alternates `sound_blu_multikill1`/`2`. It also holds debug helpers and the 2-second spawn uber.
- `patrons_damage_monitor.nut` is included by both bot scripts but is **lost**: it isn't in the repo or on the owner's machines. The only thing used from it is `recordPatronDamage(params)`, called in `create_following_bot.nut`'s `OnScriptHook_OnTakeDamage`. It was probably meant to track damage to the ambient "patron" NPCs that trigger the CBS boss. It needs rewriting, or a stub, before those scripts run cleanly.
- `.vscode/launch.json` holds the VS Code VScript debugger config (attach to localhost, Squirrel3).

## Rules for editing the .vmf

- Commit before each editing session; git history replaces manual `.bak` copies.
- The owner must close the map in Hammer++ before Claude edits the file, or Hammer will overwrite the changes.
- Keep the CRLF line endings and tab indentation the file already uses. `.gitattributes` stops git from converting them, so edits must write CRLF too.
- Every `id` (entities, solids, sides) must be unique: when adding things, use ids above the current maximum.
- Leave the Hammer++ sections (`palette_plus`, `colorcorrection_plus`, `light_plus`, `bgimages_plus`) and the existing visgroups as they are.
- Entity outputs in `connections` use the 0x1B (ESC) character as a separator, not commas.
- The file is about 14 MB (around 615k lines). Search it with grep or read it in parts; don't read it whole.
- After editing, ask the owner to open the map in Hammer++, check it visually, then compile and playtest. CompilePal is recommended for compiling and for packing custom content.

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

1. Only one `info_player_teamspawn`, with no team set. Need many RED spawns, a separate BLU (death player) spawn, and the arena logic deathrun servers usually expect (`tf_logic_arena`).
2. Outputs pointing to entities that do not exist:
   - A theater func_button targets `theater1_movelinear` (does not exist).
   - `test_button` / `test_button2` target `ms3_mono1` (the train is actually named `ms3_mono_train1`).
   - `elevator1_track_floor2` targets `elevator1_track_floor3` (does not exist), and no node leads to floor2.
3. `elevator1_track_destination` OnPass fires elevator2 outputs (SetSpeed 0 / open doors) instead of elevator1's, so elevator1 doesn't stop at the top and likely loops back down.
4. The trigger_multiple that opens elevator1's doors is parented to `elevator2` instead of `elevator1`.
5. The `trigger_hurt` (damage 200) starts disabled and nothing ever enables it.
6. Custom content must be packed into the BSP: `skullgirls/*` sounds, textures in the CUSTOMDEV and MYTEXTURES folders, and a few non-TF2 models. This content lives outside the repo (Google Drive).

## Planned features (VScript)

- Multi-kill announcer: hook `player_death`, count kills per BLU attacker within a short time window, play the matching sound once (replacing the stacked ambient_generics and test buttons). Fighting-game announcer lines too.
- Christian Brutal Sniper boss (started in `create_cbs.nut`): ambient NPCs; if they get killed, the boss spawns and chases players (base_boss / NextBot + navmesh), with announcer, voice lines and music.
- Holiday props: show a Halloween or Christmas prop set based on date / TF2 holiday checks.
- Dynamic clocks, plus movie event text and banners that change with the time of day (point_worldtext, pre-packed material/skin swaps).
- Not possible in VScript: fetching posters/titles from the internet (sandboxed, no HTTP). That would need a SourceMod plugin, and posters could only switch between pre-packed images.
- Traps: keep Hammer work to named placeholders (brush, button, marker); put the behavior in Squirrel.

## Suggested order

Fix bugs 2–5 → add spawns and arena logic → compile and test → wire the scripts into the map → multi-kill script → first traps.
