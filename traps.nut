// Trap framework, run by the map's `trap_logic` logic_script.
//
// Every trap is three named entities in Hammer, and nothing else:
//   trapNN_button  func_button with "Damage Activates", which BLU hits or shoots
//   trapNN_zone    a trigger brush that marks the kill area (only its bounds are used)
//   trapNN_marker  a func_brush outline on the floor (LIGHTS/WHITE002, tinted by rendercolor)
// NN is two digits (trap01, trap02, ...). To add a trap, copy the three in Hammer,
// move them, and renumber them. No outputs are needed: the script finds the
// pieces by name and hooks the button itself.
//
// When BLU hits the button, the marker flashes red for WARN_TIME seconds, then
// every living RED player touching the zone dies, credited to the BLU who pressed.
// RED hitting the button does nothing. By default a trap fires once per round;
// give it a cooldown in TRAP_SETTINGS to make it reusable.
//
// The button shows the state: green = ready, amber = firing, red = used.

WARN_TIME <- 0.4        // seconds of warning before the kill, so a fast player can escape
FLASH_INTERVAL <- 0.1   // marker blink rate during the warning
MAX_TRAPS <- 99

// Per-trap overrides: warn (seconds), cooldown (seconds, 0 = once per round).
TRAP_SETTINGS <- {
    [1] = { cooldown = 10 }   // trap01 is the foyer test copy: reusable, for testing
}

TEAM_RED <- 2
TEAM_BLU <- 3
DMG_BLAST <- 64

COLOR_READY <- "40 255 60"
COLOR_FIRING <- "255 170 0"
COLOR_USED <- "255 30 30"
COLOR_MARKER_IDLE <- "150 30 30"
COLOR_MARKER_FLASH <- "255 0 0"
COLOR_MARKER_DARK <- "40 0 0"

SOUND_WARN <- "ambient/alarms/klaxon1.wav"
SOUND_KILL <- "ambient/explosions/explode_4.wav"
SOUND_DENIED <- "buttons/button10.wav"
PrecacheSound(SOUND_WARN)
PrecacheSound(SOUND_KILL)
PrecacheSound(SOUND_DENIED)

::Traps <- {}
::TrapLogic <- self

function TrapName(n, part)
{
    return format("trap%02d_%s", n, part)
}

function PlaySound(sound, origin)
{
    EmitSoundEx({
        sound_name = sound
        origin = origin
        sound_level = 90
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
    })
}

function SetColor(ent, color, delay = 0.0)
{
    if (ent != null && ent.IsValid())
        EntFireByHandle(ent, "Color", color, delay, null, null)
}

function SetupTrap(n, button)
{
    local zone = Entities.FindByName(null, TrapName(n, "zone"))
    if (zone == null)
    {
        printl("[traps] " + TrapName(n, "button") + " has no " + TrapName(n, "zone") + ", skipped")
        return
    }
    local settings = n in TRAP_SETTINGS ? TRAP_SETTINGS[n] : {}
    local trap = {
        index = n
        button = button
        zone = zone
        marker = Entities.FindByName(null, TrapName(n, "marker"))
        warn = "warn" in settings ? settings.warn : WARN_TIME
        cooldown = "cooldown" in settings ? settings.cooldown : 0.0
        state = "ready"   // ready, firing, used
        presser = null
    }
    Traps[n] <- trap

    // Hook the button from script, so copies in Hammer need no outputs.
    // ConnectOutput runs the function in the button's scope with `activator` set.
    button.ValidateScriptScope()
    local scope = button.GetScriptScope()
    scope.trapIndex <- n
    scope.Trap_OnPressed <- function() { ::TrapLogic.GetScriptScope().Trap_Press(trapIndex, activator) }
    button.ConnectOutput("OnPressed", "Trap_OnPressed")
    button.ConnectOutput("OnDamaged", "Trap_OnPressed")

    SetColor(button, COLOR_READY)
    SetColor(trap.marker, COLOR_MARKER_IDLE)
}

function Trap_Press(n, activator)
{
    if (!(n in Traps))
        return
    local trap = Traps[n]
    if (trap.state != "ready")
        return
    if (activator == null || !activator.IsValid() || !activator.IsPlayer() || activator.GetTeam() != TEAM_BLU)
    {
        PlaySound(SOUND_DENIED, trap.button.GetCenter())
        return
    }

    trap.state = "firing"
    trap.presser = activator
    SetColor(trap.button, COLOR_FIRING)
    PlaySound(SOUND_WARN, trap.zone.GetCenter())

    // Blink the marker during the warning.
    local t = 0.0
    local lit = true
    while (t < trap.warn)
    {
        SetColor(trap.marker, lit ? COLOR_MARKER_FLASH : COLOR_MARKER_DARK, t)
        lit = !lit
        t += FLASH_INTERVAL
    }
    EntFireByHandle(self, "RunScriptCode", "Trap_Kill(" + n + ")", trap.warn, null, null)
}

// True if the player's collision box overlaps the zone's box.
function InZone(player, zone)
{
    local zo = zone.GetOrigin()
    local zmin = zo + zone.GetBoundingMins()
    local zmax = zo + zone.GetBoundingMaxs()
    local po = player.GetOrigin()
    local pmin = po + player.GetBoundingMins()
    local pmax = po + player.GetBoundingMaxs()
    return pmin.x <= zmax.x && pmax.x >= zmin.x
        && pmin.y <= zmax.y && pmax.y >= zmin.y
        && pmin.z <= zmax.z && pmax.z >= zmin.z
}

function Trap_Kill(n)
{
    local trap = Traps[n]
    local attacker = trap.presser
    if (attacker != null && !attacker.IsValid())
        attacker = null
    local killed = 0

    for (local i = 1; i <= MaxClients(); i++)
    {
        local player = PlayerInstanceFromIndex(i)
        if (player == null || player.GetTeam() != TEAM_RED)
            continue
        if (NetProps.GetPropInt(player, "m_lifeState") != 0)
            continue
        if (!InZone(player, trap.zone))
            continue
        player.TakeDamageEx(attacker, attacker, null, Vector(0, 0, 0), player.GetCenter(), 99999, DMG_BLAST)
        killed++
    }
    if (killed > 0)
        PlaySound(SOUND_KILL, trap.zone.GetCenter())

    trap.presser = null
    trap.state = "used"
    SetColor(trap.button, COLOR_USED)
    SetColor(trap.marker, COLOR_MARKER_DARK)
    if (trap.cooldown > 0)
        EntFireByHandle(self, "RunScriptCode", "Trap_Rearm(" + n + ")", trap.cooldown, null, null)
}

function Trap_Rearm(n)
{
    local trap = Traps[n]
    trap.state = "ready"
    SetColor(trap.button, COLOR_READY)
    SetColor(trap.marker, COLOR_MARKER_IDLE)
}

for (local n = 1; n <= MAX_TRAPS; n++)
{
    local button = Entities.FindByName(null, TrapName(n, "button"))
    if (button != null)
        SetupTrap(n, button)
}
printl("[traps] " + Traps.len() + " trap(s) ready")
