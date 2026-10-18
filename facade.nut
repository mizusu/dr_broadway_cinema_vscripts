// Facade signage, run by the map's `facade_logic` logic_script.
//
// - The Art Deco clock on the tower shows the real local time of the machine
//   running the map (the server's clock). Its hands are func_brushes named
//   clock_hand_hour / clock_hand_minute, built pointing at 12 with their origin
//   at the clock's center; the clock faces +y, so turning clockwise as seen from
//   the street is a negative pitch.
// - The marquee's `marquee_title` point_worldtext gets a random "Now Showing"
//   title at the start of every round (the script reruns on each round restart).

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

function SetTitle()
{
    local marquee = Entities.FindByName(null, "marquee_title")
    if (marquee == null)
        return
    local title = MARQUEE_TITLES[RandomInt(0, MARQUEE_TITLES.len() - 1)]
    EntFireByHandle(marquee, "SetText", title, 0, null, null)
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
