# Trap and BLU path plan (draft)

A first draft for the owner to edit. Locations come from the .vmf (top-down slices). Anything marked **(guess)** needs the owner to confirm. Coordinates are Hammer units, and z is the floor height.

## Ground rules

- **Only BLU can trigger traps.** Every trap function checks that the activator is on BLU. Buttons are pressed with +use or by shooting, but the check runs in the script, so RED shooting a button through a window does nothing.
- **Each trap fires once per round**, with a short cooldown shown on the button (a light or skin change), so BLU has to time it.
- **Every trap gives a warning first** (a sound, light or rumble, 0.3–0.5 s before it kills) and can be escaped by a fast or careful player. Traps nobody can avoid make people leave deathrun servers.
- **Hammer only holds named placeholders:** the moving brush (`func_door`/`func_movelinear`), the `trigger_hurt` or `trigger_push` volume, the BLU button and a marker. All behavior lives in Squirrel.
- **Naming:** `trapNN_<part>`, for example `trap06_floor`, `trap06_hurt` and `trap06_button`. The script finds everything by name.

## BLU path: booths linked by teleporters

BLU never walks the RED route. They move between sealed rooms that have windows over each section, using **BLU-only teleporter pads** (a `trigger_teleport` with a `filter_activator_tfteam` set to BLU). RED can't enter a booth, because the booths have no doors.

| Booth | Where | Overlooks | Traps |
|---|---|---|---|
| **B0 Balcony** (spawn) | Front facade, z 720 (exists) | Plaza and entrance | T1 |
| **B1 Projection booth** | West wing, between the two theaters (guess: above the corridor, z ≈ 900–1100) | Theater 1, the corridor, the trap theater | T2, T3 |
| **B2 Lobby control room** | Next to the elevator lobby, z ≈ 720–790 | Elevator lobby | T4, T5 |
| **B3 Lighting box** | Back of the opera hall, in or near the curved boxes (y ≈ −7,600, z ≈ 3,300) | Stage and seats | T6–T9 |
| **B4 Hotel security office** | Hotel floor, z 4,864 (guess: an unused room off the H corridor) | Hotel corridors | T10–T12 |

**Sealing the balcony (needed now):** the balcony gallery leads straight to the elevator lobby. Either block that corridor (wall or `func_respawnroomvisualizer`), or close the balcony off completely so BLU's only way out is the B0 → B1 pad.

## Traps along the route

| # | Section | Idea | Hammer placeholders | Script |
|---|---|---|---|---|
| T1 | Entrance hallway | **Popcorn machine overload:** fire and steam along the hallway | `trigger_hurt`, particles | Enable for 2 s, sound |
| T2 | Theater 1 (passed through) | **Lights out, rows drop:** lights cut, then a band of seat rows sinks | `func_door` rows, light names | Lights off → 0.5 s → open the doors, close after 4 s |
| T3 | Corridor between the theaters | **The push trap (your design):** RED gets pushed into the trap theater, the doors lock, and "the movie kills them" | existing `theater1_trigger_push`, a door, `trigger_hurt` in the theater | Enable pushes for 3 s, lock the door, hurt after 2 s |
| T4 | Elevator lobby | **Anti-camping sweep:** a rotating laser or spotlight bar sweeps the lobby while players wait | `func_rotating` + parented `trigger_hurt` | Start/stop it, one sweep |
| T5 | Elevator ride (optional) | **Out of order:** BLU stalls a car mid-shaft for 5 s, with flickering lights (delays, doesn't kill) | uses the `elevator1/2` names | `SetSpeed 0`, then resume after 5 s |
| T6 | Opera stage | **Stage trapdoor:** a classic theater trapdoor drops players into the pit under the stage | `func_door` floor panel, `trigger_hurt` under the stage | Open, close after 3 s |
| T7 | Opera stage | **Fly-loft accident:** sandbags or a lighting truss falls from above the stage | `func_door` (falling) with props parented, `trigger_hurt` | Drop, reset next round |
| T8 | Proscenium / orchestra pit | **Curtain crusher:** the main curtain closes fast across the stage opening | 2 `func_door` curtains, block damage | Close fast, reopen slowly |
| T9 | Audience seats (middle aisle) | **The chandelier** (Phantom of the Opera): it drops onto the middle of the seats | `func_door`/`func_movelinear` + chandelier prop, `trigger_hurt` | Shake → drop → hurt |
| T10 | Corridor to the 2nd elevator | **Sky-high windows:** glass shatters and a push sends RED out of the tower | `func_breakable` glass, `trigger_push` outward | Break the glass, push for 2 s |
| T11 | Hotel H corridor | **Housekeeping cart:** a cart charges down the corridor | `func_tracktrain` cart with hurt, `path_track`s | Run once |
| T12 | Last room before the teleporter | **Last call:** the floor gives way or the room floods with fire | `func_door` floor or `trigger_hurt` + particles | Open or enable for 3 s |

That makes 12 slots: 3–4 in the west wing, 2 at the lobby, 4 in the opera hall and 3 at the top. That's typical for a deathrun of this length. Not every slot needs building before the first playtest.

## Ending

At the moment, RED teleports to the end tower and the round can't end. Suggested finale, the **rooftop showdown**: when the first RED touches `teleport_origin1`, the script also teleports BLU to an arena on the end tower. RED (with weapons) fights BLU, and the round ends when BLU dies or all RED are dead. Another option is to have the end tower give weapons and a path to BLU's last booth.

## Still to build (not traps)

- The trap theater's death mechanism and a lockable door (T3).
- The second elevator, from the elevator-arrival floor (z ≈ 3,968) up to the hotel (z ≈ 4,864), about 900 units.
- The end tower and the finale arena.

## Questions for the owner

1. Which west-wing theater do players pass through, and which is the trap? Most of the push triggers point south (yaw 268), so my guess is that the north theater (screen at y ≈ −2,080) is passed through and the south theater (screen at y ≈ −5,450) is the trap.
2. Where is "the second floor" you go up to after theater 1, and where are its stairs?
3. Where should the second elevator be? I'm guessing the left (west) side of the elevator-arrival floor.
4. Are you happy with the rooftop showdown ending?
5. Any traps you already had in mind for a section?
