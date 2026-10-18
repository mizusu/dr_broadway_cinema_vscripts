# Vision: dr_skullgirls_cinema

The owner's intent for the map, in their words where possible. Use it to judge design choices (layout, lighting, sound, traps) and to keep the map's identity when cutting scope.

## Where it comes from

The owner has wanted to make this map since 2020. It comes from a childhood memory: joining a Garry's Mod server that was a theater map, with halls, food courts, bathrooms, hallways and theaters that could play video and sound. **The Skullgirls main menu music was playing when they joined**, and that stuck. This map is meant to recreate that feeling as a TF2 deathrun.

## Look and feel

- **A grand, luxurious, "almost royal" movie palace**, sky-high and fancy. The references are 1920s–30s American movie palaces: Art Deco (Radio City Music Hall's Grand Foyer) and ornate revival styles (LA's Tower Theatre, the Fox Theatre). The owner described it as "art deco, 70s"; the references themselves are from the 1920s–30s.
- **Architecture should carry the space:** tall red-and-gold halls, columns, grand staircases, balconies, chandeliers, patterned carpet, murals.
- **Lighting is dark and warm** in the references: deep reds and golds lit by pools of amber light from chandeliers, sconces and ceiling coves, not flat bright light. This is the target for the brightness pass.
- **Outside views matter:** windows show the surrounding city, and the high floors (the hotel level) should make it clear how high up players are.
- **Movie posters** (real and parody) line the walls. The owner has a poster collection to choose from.

## Sound

- **Skullgirls music in the background, the main menu theme and/or the character select theme.** It plays **by random chance, not guaranteed, and never looping**, because constant music gets annoying fast. These tracks are not in the map yet. `tf/sound/skullgirls/` currently has the multi-kill sounds, `round_start1`, red-team round sounds, `cbs_theme` and `stone_cold_motivator_theme`.
- **Announcers, fighting-game style:** the Halo multi-kill announcer (double kill, triple kill, overkill, killtacular...) is the main one. For big multi-kills, the **Capcom vs. SNK 2 announcer sometimes chimes in** too. The reference clips (`round_start1-4`, `double_ko`, `big_damage`, `good one` and others) are in `user-ideas/Skullgirls Cinema/`.

## Reference folder: `user-ideas/`

The owner's personal mood board (about 240 MB of images and sounds), sorted by part of the route:

| Folder | Use for |
|---|---|
| `Grand_Foyer_3.jpg` (Radio City Music Hall) | **The first room players enter**, the main inspiration |
| `Theater Building Exterior Ideas/` | The facade and spawn plaza (Tower Theatre, LA) |
| `Theater Lobby Ideas/` | Lobbies and foyers |
| `Corridor-Passages-Overall-WalkingI-deas/` | Hallways between rooms |
| `Actual Theater Room Ideas/` | The theaters (Hippodrome, Paramount, Congress) |
| `Mid-Run Room Ideas/` | The middle of the route (Fox Theatre and others) |
| `Final Room Ideas/` | The last room (Lyric lobby) |
| `Movie posters/` | Wall posters (mostly memes and parodies; not reviewed for style) |
| `*.wav` in `Skullgirls Cinema/` | Announcer and FGC sound clips |

## Style guide, from the references

Written after reviewing all 45 room images (2026-10-18). Filenames are relative to `user-ideas/Skullgirls Cinema/` unless noted.

### The overall picture

Almost every reference is a **1920s–30s movie palace interior**: warm gold, cream and deep red, lit by chandeliers, sconces and cove lights, with the darkness around them left dark. A smaller set is **modern multiplex** (box office, concessions, neon, poster lightboxes, numbered screen doors). The mix the references point to is **palace architecture with working-cinema features**: a grand hall that still has a box office, a snack bar and "Now Showing" signs.

**Palette:** deep red (carpet, curtains, seats, faux-marble columns), gold and brass (rails, ornament, frames), cream and ivory (marble, plaster), dark wood, with blue as an accent (painted-sky ceilings, starry ceilings).

**Lighting:** warm amber pools from crystal chandeliers, wall sconces and lanterns. Cove lighting traces domes, arches and balcony fronts. **Rows of exposed bulbs** outline marquees, staircase stringers and arches. Rooms are dark between the light sources. Neon only outside (blade sign, marquee) and in the modern lobby bits.

**Recurring signature elements** (the things that make it read as "this map"):
- **Grand staircases**: twin or split stairs, red carpet, brass rails, sometimes guarded by statues. They appear in about 10 references.
- **Chandeliers**, crystal or Art Deco glass cylinders.
- **Mezzanine balconies** wrapping around tall halls, with ornate railings.
- **Columns**: fluted marble, red faux-marble (Fox), dark wood.
- **Patterned red carpet**, terrazzo or checkerboard marble floors.
- **Lit poster frames** ("Coming Soon"), velvet-rope stanchions, a box office booth, a popcorn cart.
- **Clocks**: the Tower Theatre's clock tower and the Abraj Al Bait clock tower (`03.jpg`). This fits the planned dynamic clocks feature.

### By part of the route

| Route section | References | What to take from them | Trap and gameplay hooks |
|---|---|---|---|
| **Spawn plaza and facade** | `Theater Building Exterior Ideas/` (Tower, Los Angeles Theatre), `chicago.jpg`, `7681644180_…jpg` (Fox Detroit at night), `5402871543_…jpg` (Globe), `building-entrance-nicosia…jpg`, `guanajuato-juarez…jpg` | A tall ornate facade with a **vertical blade sign** lit by bulbs or neon, a **marquee** with chaser lights and "Now Showing" text, an uplit colonnade portico with a coffered ceiling, all at night | The marquee is a natural spot for `point_worldtext` titles that change per round. The facade is what RED stares at while waiting, so it should be the showpiece of the outdoors. |
| **Entrance and ticket hall** | `8eaf726…png`, `e6c29434…jpg` (Paramount facades with box office), `26080742-red-carpet…jpg`, `old-theater-entrance…jpg`, `54a1af0c…jpg` | **Red carpet with velvet ropes** between lit poster frames, leading to wooden double doors, plus a box office booth under a bulb-lit canopy and a starry ceiling | A good start gate: the round begins at the "ticket turnstiles". The velvet-rope lanes funnel RED. |
| **Grand foyer (first big room)** | `Grand_Foyer_3.jpg` (Radio City, top level), `Theater Lobby Ideas/Grand-Gallery-Lobby_1.jpg`, `paramount-theater-interior-1.jpg`, `00504dea…jpg` (LA Theatre lobby), `WangLobby.jpg`, `5499128563_…jpg` | A **tall hall** with mezzanines on both sides, a grand staircase at the far end, chandeliers down the middle, columns, concession counters along the walls, and terrazzo, mosaic or carpet floors | **Falling chandeliers**, a **collapsing staircase** (the steps flatten into a slide), concession-counter traps (popcorn machine overload). BLU can watch from a mezzanine booth. |
| **Corridors** | `Corridor-Passages-Overall-WalkingI-deas/`, `double-door-idea.jpg`, `5487634492_…jpg` / `5487634606_…jpg` (top level; gallery halls with framed photos) | **Curving halls lined with lit poster frames**, cove-lit ceilings, numbered screen doors in lit portals | Short, tight connectors between the big rooms, which is where quick traps (crushers, floor drops) belong. The posters can change per round. |
| **The theaters** | `Actual Theater Room Ideas/` (Hippodrome Birmingham and Baltimore, Congress, Paramount), `Los-Angeles-Theater-Interior.jpg`, `Theater Lobby Ideas/Paramount-Theatre-Seattle.jpg` (the Auditorium Theatre's arches of bulbs) | A **horseshoe auditorium**, red seats in curved stepped rows, balcony fronts lined with lamps, **opera boxes** with chandeliers flanking a gilded **proscenium arch** around the screen, **domed ceilings with cove lighting and a glowing oculus** | **Rows of seats folding away**, a fire curtain (safety curtain) dropping, a **projector beam** that kills, the stage trapdoor, the house lights going out. The opera boxes are natural BLU booths. |
| **Mid-run showpiece (Fox)** | `Mid-Run Room Ideas/` (Fox Theatre Detroit and St. Louis), `Fabulous-Fox-BASIC.jpg` | The most exotic room: giant **red faux-marble columns**, a deep carved ceiling around a **blue painted-sky panel**, hanging lanterns, a red-carpet stair **guarded by lion statues** | Lion statues that breathe fire or roll, lanterns that drop, a ceiling that lowers. It sets up the opera hall. |
| **Final room** | `Final Room Ideas/` (`85_LyricLobby01.jpg`, `91d9636b-…jpg`), `unnamed.jpg` (wood-paneled rotunda with a skylight dome) | A marble staircase splitting into **two curved balconies**, a red-draped curtain arch at the top like a stage, lantern sconces, a **checkerboard marble floor**, round columns around a domed ceiling | **The finish line is the stage curtain at the top of the split stair.** The last BLU-vs-RED fight happens on the checkerboard floor ("like a fighting-game stage"). |
| **Hotel tower (version 2)** | `03.jpg` (Abraj Al Bait clock tower, Mecca) | A **supertall tower crowned by a huge clock**, rows of windows, and the feeling of height | The map's tower crown (up to z 6,592) could carry a giant clock face that shows the real time (the planned dynamic clocks). |

### Building it in TF2 and Source

- **TF2's stock content is mostly 1960s industrial**, so ornate detail has to come from **props** (Source has some ornate columns, chandeliers, lamps and statues, especially in other Valve games' content), **custom textures** for the patterned carpet, marble, gold trim and painted ceilings, and **light** (cove lighting and bulb rows sell "grand" cheaply).
- **Repetitive architecture** (colonnades, arches, balcony runs, seat rows, bulb rows, stair runs) can be **generated into the .vmf by script**, so Hammer work is mostly adjusting and texturing.
- Keep rooms **tall rather than wide**. Grandness comes from height, chandeliers and balconies, and keeps the deathrun route tight.
- Keep the **lighting dark and warm**, but give every trap its own pool of light so RED can read it.
