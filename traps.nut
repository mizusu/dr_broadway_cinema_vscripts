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
TRAP_DEBUG <- true      // print zone bounds and RED positions to the console on every fire
// Local testing only (never on a dedicated server): each RED bot gets a trap (the first
// bot trap01, the next trap02, ...) and is put in its square at round start and every time
// that trap re-arms, so you can just keep hitting the buttons.
TRAP_AUTO_PLACE <- true
TRAP_RESPAWN_DELAY <- 2.0   // with TRAP_AUTO_PLACE, a dead test bot respawns in its square after this

// Per-trap overrides:
//   warn      seconds of warning (default WARN_TIME)
//   cooldown  seconds until it re-arms (default 0 = once per round)
//   kill      how RED dies: "explode" (gibs, the default), "ragdoll" (no gibs), or
//             "launch" (a critical hit: no gibs, the crit death scream, and the
//             ragdoll flies off)
// The three foyer test copies are reusable, for testing.
TRAP_SETTINGS <- {
    [1] = { cooldown = 3, kill = "explode" },
    [2] = { cooldown = 3, kill = "ragdoll" },
    [3] = { cooldown = 3, kill = "launch" }
}

LAUNCH_SPEED <- 900     // "launch": sideways speed of the body, away from the zone's middle
LAUNCH_UP <- 1100       // "launch": upward speed

TEAM_RED <- 2
TEAM_BLU <- 3
DMG_CLUB <- 128
DMG_BLAST <- 64
DMG_NEVERGIB <- 4096
DMG_CRITICAL <- 1048576   // DMG_ACID, which TF2 uses as its crit flag

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
        kill = "kill" in settings ? settings.kill : "explode"
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

    // Whatever happens below, the trap must still reset afterwards.
    try
    {
        if (TRAP_DEBUG)
        {
            local zo = trap.zone.GetOrigin()
            printl(format("[traps] trap%02d fired. zone %s .. %s", n,
                (zo + trap.zone.GetBoundingMins()).ToKVString(), (zo + trap.zone.GetBoundingMaxs()).ToKVString()))
        }
        foreach (player in RedPlayers())
        {
            local inside = InZone(player, trap.zone)
            if (TRAP_DEBUG)
                printl(format("[traps]   RED %s at %s: %s", PlayerName(player),
                    player.GetOrigin().ToKVString(), inside ? "in the zone, killed" : "outside"))
            if (!inside)
                continue
            KillPlayer(player, attacker, trap)
            killed++
        }
        if (killed > 0)
            PlaySound(SOUND_KILL, trap.zone.GetCenter())
    }
    catch (err)
    {
        printl("[traps] trap" + n + " kill failed: " + err)
    }

    trap.presser = null
    trap.state = "used"
    SetColor(trap.button, COLOR_USED)
    SetColor(trap.marker, COLOR_MARKER_DARK)
    if (trap.cooldown > 0)
        EntFireByHandle(self, "RunScriptCode", "Trap_Rearm(" + n + ")", trap.cooldown, null, null)
}

function KillPlayer(player, attacker, trap)
{
    local force = Vector(0, 0, 0)
    local dmgType = DMG_BLAST
    if (trap.kill == "ragdoll")
        dmgType = DMG_CLUB | DMG_NEVERGIB
    else if (trap.kill == "launch")
    {
        // The ragdoll keeps the player's velocity, so throw the player first.
        dmgType = DMG_CLUB | DMG_NEVERGIB | DMG_CRITICAL
        local away = player.GetOrigin() - trap.zone.GetCenter()
        away.z = 0
        if (away.Length() < 16)
        {
            local yaw = RandomFloat(0, 6.2832)
            away = Vector(cos(yaw), sin(yaw), 0)
        }
        away.Norm()
        local velocity = away * LAUNCH_SPEED + Vector(0, 0, LAUNCH_UP)
        player.SetAbsVelocity(velocity)
        force = velocity * 100
    }
    player.TakeDamageEx(attacker, attacker, null, force, player.GetCenter(), 99999, dmgType)
}

// Hooks game events for this round only: the callbacks are dropped at round end, so
// they don't pile up as the logic_script re-runs each round. (Same helper as in
// create_cbs.nut.)
function CollectEventsInScope(events)
{
    local events_id = UniqueString()
    getroottable()[events_id] <- events

    foreach (name, callback in events)
        events[name] = callback.bindenv(this)

    local cleanup_user_func, cleanup_event = "OnGameEvent_scorestats_accumulated_update"
    if (cleanup_event in events)
        cleanup_user_func = events[cleanup_event]

    events[cleanup_event] <- function(params)
    {
        if (cleanup_user_func)
            cleanup_user_func(params)

        delete getroottable()[events_id]
    }
    __CollectGameEventCallbacks(events)
}

function PlayerName(player)
{
    return NetProps.GetPropString(player, "m_szNetname")
}

// Twice a second, any living RED test bot that isn't in its trap's square is put there,
// and a dead one is respawned there after TRAP_RESPAWN_DELAY. Polling (rather than placing
// once at round start) also catches bots that join or spawn late. Arena ends the round
// when the last RED dies, so dr_test.cfg adds one spare RED bot that has no trap.
::TrapBotDiedAt <- {}   // bot entity index -> Time() it was first seen dead

function TrapAutoThink()
{
    TrapTestPlace(false, 0, true)
    return 0.5
}

// Living RED players.
function RedPlayers()
{
    local list = []
    for (local i = 1; i <= MaxClients(); i++)
    {
        local player = PlayerInstanceFromIndex(i)
        if (player != null && player.GetTeam() == TEAM_RED && NetProps.GetPropInt(player, "m_lifeState") == 0)
            list.append(player)
    }
    return list
}

function Trap_Rearm(n)
{
    local trap = Traps[n]
    trap.state = "ready"
    SetColor(trap.button, COLOR_READY)
    SetColor(trap.marker, COLOR_MARKER_IDLE)
}

// --- Local testing (dr_trap_test.cfg). The cfg calls these with
// `ent_fire trap_logic CallScriptFunction <name>`, which needs no quotes or parentheses.

// You on BLU, every bot on RED, so the bots are the victims. Restart the round afterwards.
function TrapTestTeams()
{
    for (local i = 1; i <= MaxClients(); i++)
    {
        local player = PlayerInstanceFromIndex(i)
        if (player == null)
            continue
        local team = IsPlayerABot(player) ? TEAM_RED : TEAM_BLU
        if (player.GetTeam() != team)
            player.ForceChangeTeam(team, true)
    }
    printl("[traps] you are BLU, the bots are RED")
}

// Each RED bot gets a trap, in order (the lowest player index gets the lowest trap), and
// stands in the middle of its square. Pass n to place only trap n's bot, and onlyOutside
// to leave bots that are already in their square alone. With moveHost, you also go to
// the balcony, in front of the buttons, and every trap re-arms.
function TrapTestPlace(moveHost = true, n = 0, onlyOutside = false)
{
    local numbers = []
    foreach (k, trap in Traps)
        numbers.append(k)
    numbers.sort()
    local bots = []
    for (local i = 1; i <= MaxClients(); i++)
    {
        local player = PlayerInstanceFromIndex(i)
        if (player != null && player.GetTeam() == TEAM_RED && IsPlayerABot(player))
            bots.append(player)
    }
    for (local i = 0; i < numbers.len() && i < bots.len(); i++)
    {
        local trap = Traps[numbers[i]]
        local bot = bots[i]
        if (n != 0 && numbers[i] != n)
            continue
        local index = bot.entindex()
        if (NetProps.GetPropInt(bot, "m_lifeState") != 0)
        {
            if (!onlyOutside)
                continue   // dead until the next round (arena)
            if (!(index in TrapBotDiedAt))
                TrapBotDiedAt[index] <- Time()
            if (Time() - TrapBotDiedAt[index] < TRAP_RESPAWN_DELAY)
                continue
            bot.ForceRespawn()
            if (NetProps.GetPropInt(bot, "m_lifeState") != 0)
                continue
        }
        if (index in TrapBotDiedAt)
            delete TrapBotDiedAt[index]
        if (onlyOutside && InZone(bot, trap.zone))
            continue
        local zo = trap.zone.GetOrigin()
        local zmin = zo + trap.zone.GetBoundingMins()
        local zmax = zo + trap.zone.GetBoundingMaxs()
        local pos = Vector((zmin.x + zmax.x) / 2, (zmin.y + zmax.y) / 2, zmin.z + 8)
        bot.Teleport(true, pos, true, QAngle(0, 90, 0), true, Vector(0, 0, 0))
        printl(format("[traps] put %s in trap%02d", PlayerName(bot), numbers[i]))
    }
    if (bots.len() <= numbers.len() && !onlyOutside)
        printl(format("[traps] %d RED bot(s) for %d traps: add more with  bot -team red (one extra keeps the round going)", bots.len(), numbers.len()))

    local host = GetListenServerHost()
    if (moveHost && host != null && (1 in Traps))
    {
        local b = Traps[1].button.GetCenter()
        host.Teleport(true, Vector(b.x + 96, b.y + 160, 721), true, QAngle(10, 270, 0), true, Vector(0, 0, 0))
    }
    if (moveHost)
        foreach (k, trap in Traps)
            Trap_Rearm(k)
}

function TrapTestRearm()
{
    local logic = ::TrapLogic.GetScriptScope()
    foreach (n, trap in Traps)
        logic.Trap_Rearm(n)
    printl("[traps] all traps re-armed")
}

for (local n = 1; n <= MAX_TRAPS; n++)
{
    local button = Entities.FindByName(null, TrapName(n, "button"))
    if (button != null)
        SetupTrap(n, button)
}
printl("[traps] " + Traps.len() + " trap(s) ready")
if (Traps.len() > 0 && TRAP_AUTO_PLACE && !IsDedicatedServer())
{
    printl("[traps] auto-placing RED test bots (TRAP_AUTO_PLACE)")
    AddThinkToEnt(self, "TrapAutoThink")
    printl("[traps] remote firing: as BLU, say !t1, !t2, ... in chat (or trap1, trap2, ... in the console)")
    CollectEventsInScope({
        // Local testing: fire a trap remotely by chat, as if you hit its button.
        function OnGameEvent_player_say(params)
        {
            local text = strip(params.text.tolower())
            if (text.len() < 3 || text.slice(0, 2) != "!t")
                return
            local digits = text.slice(2)
            if (digits.len() > 3 && digits.slice(0, 3) == "rap")   // !trap1 works too
                digits = digits.slice(3)
            local n
            try { n = digits.tointeger() } catch (err) { return }
            local player = GetPlayerFromUserID(params.userid)
            if (!(n in Traps))
            {
                printl("[traps] no trap" + n)
                return
            }
            printl(format("[traps] %s fired trap%02d remotely", PlayerName(player), n))
            Trap_Press(n, player)
        }
    })
}
