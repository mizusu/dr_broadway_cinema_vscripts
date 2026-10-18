// Facade signage, run by the map's `facade_logic` logic_script.
//
// - The Art Deco clock on the tower shows the real local time of the machine
//   running the map (the server's clock). Its hands are func_brushes named
//   clock_hand_hour / clock_hand_minute, built pointing at 12 with their origin
//   at the clock's center; the clock faces +y, so turning clockwise as seen from
//   the street is a negative pitch.
// - The marquee's `marquee_title` point_worldtext gets a random "Now Showing"
//   title at the start of every round (the script reruns on each round restart),
//   re-centered on the facade by its length (worldtext grows from its origin
//   toward -x as seen from the street).
// - The marquee and blade-sign bulbs (env_sprites chase_a/b/c) chase: one group
//   of three is dark at a time and the dark group steps along.
// - The `paparazzi_flash` sprites along the red carpet pop at random, like
//   press cameras.

MARQUEE_TITLES <- [
    "NOW SHOWING: SKULLGIRLS 2ND ENCORE",
    "NOW SHOWING: THE BRUTAL SNIPER",
    "NOW SHOWING: CAPCOM VS SNK 2 - THE MOVIE",
    "NOW SHOWING: KILLTACULAR",
    "NOW SHOWING: DEATHRUN - THE MUSICAL",
    "NOW SHOWING: MANN VS MACHINE 2",
    "NOW SHOWING: RETURN OF THE ACTIVATOR",
    "NOW SHOWING: AFK - A TRUE STORY",
    "TONIGHT: GRAND PREMIERE"
]

CLOCK_INTERVAL <- 1.0
MARQUEE_CENTER_X <- 96.0
TITLE_GLYPH_WIDTH <- 0.51   // worldtext glyph width as a fraction of its textsize
CHASE_GROUPS <- ["chase_a", "chase_b", "chase_c"]
CHASE_STEP <- 0.18
chaseDark <- 0

function SetTitle()
{
    local marquee = Entities.FindByName(null, "marquee_title")
    if (marquee == null)
        return
    local title = MARQUEE_TITLES[RandomInt(0, MARQUEE_TITLES.len() - 1)]
    EntFireByHandle(marquee, "SetText", title, 0, null, null)
    local size = NetProps.GetPropFloat(marquee, "m_flTextSize")
    if (size <= 0)
        size = 70.0
    local o = marquee.GetOrigin()
    marquee.SetAbsOrigin(Vector(MARQUEE_CENTER_X + TITLE_GLYPH_WIDTH * size * title.len() / 2.0, o.y, o.z))
}

function ChaseThink()
{
    EntFire(CHASE_GROUPS[chaseDark], "ShowSprite")
    chaseDark = (chaseDark + 1) % CHASE_GROUPS.len()
    EntFire(CHASE_GROUPS[chaseDark], "HideSprite")
    return CHASE_STEP
}

function FlashThink()
{
    local flashes = []
    for (local e = null; (e = Entities.FindByName(e, "paparazzi_flash")) != null; )
        flashes.append(e)
    if (flashes.len() > 0)
    {
        local burst = RandomInt(1, 3)   // a photographer often fires two or three in a row
        local flash = flashes[RandomInt(0, flashes.len() - 1)]
        for (local k = 0; k < burst; k++)
        {
            EntFireByHandle(flash, "ShowSprite", "", k * 0.15, null, null)
            EntFireByHandle(flash, "HideSprite", "", k * 0.15 + 0.06, null, null)
        }
    }
    return RandomFloat(0.25, 1.4)
}

function SetHand(name, fraction)
{
    local hand = Entities.FindByName(null, name)
    if (hand != null)
        hand.SetAbsAngles(QAngle(-360.0 * fraction, 0, 0))
}

function ClockThink()
{
    local t = {}
    LocalTime(t)
    local minutes = t.minute + t.second / 60.0
    SetHand("clock_hand_minute", minutes / 60.0)
    SetHand("clock_hand_hour", ((t.hour % 12) + minutes / 60.0) / 12.0)
    return CLOCK_INTERVAL
}

SetTitle()
AddThinkToEnt(self, "ClockThink")

// Only one think function per entity, so the chaser and the flashes run on
// helper entities spawned here.
chaser <- SpawnEntityFromTable("info_target", { targetname = "facade_chaser" })
flasher <- SpawnEntityFromTable("info_target", { targetname = "facade_flasher" })
chaser.ValidateScriptScope()
chaser.GetScriptScope().ChaseThink <- ChaseThink.bindenv(this)
AddThinkToEnt(chaser, "ChaseThink")
flasher.ValidateScriptScope()
flasher.GetScriptScope().FlashThink <- FlashThink.bindenv(this)
AddThinkToEnt(flasher, "FlashThink")
