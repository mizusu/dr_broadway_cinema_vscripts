// Automatic elevators, run by the map's `elevator_logic` logic_script.
//
// Each car waits at the lobby with its doors open. When a living RED player
// steps in, a countdown starts; then the car and landing doors close and the
// car rides up. At the top the doors open, and once the car is empty (or after
// TOP_MAX_WAIT seconds) it closes up and returns to the lobby by itself.
// There are no buttons, so nobody can send a car up empty or grief it.
//
// Doors never close on a player: while someone stands in the doorway the car
// waits (and pushes them out after BLOCK_PUSH_TIME). As soon as the doorway is
// clear, an invisible player clip seals it so nobody can step back in while the
// doors close; a griefer is simply left behind. If the doors still fail to
// close, they reopen and the car tries again instead of leaving.
//
// Map entities per car N (see CLAUDE.md):
//   elevatorN                         func_movelinear car: Open = ride up, Close = ride down.
//                                     OnFullyOpen/OnFullyClosed -> elevator_logic RunScriptCode
//                                     Elevator_OnArrive(N, floor), floor 0 = lobby, 1 = top.
//   elevatorN_doorleft / _doorright   car doors, parented to the car
//   elevatorN_landing_bottom_left/_right, elevatorN_landing_top_left/_right
//                                     landing doors in the shaft frames, closed while the car is away
//   elevatorN_doorway_clip_bottom/_top func_brush player clips outside the landing doors (start disabled)

DEPART_DELAY <- 5.0      // seconds from the first RED stepping in until the doors close
DOOR_TIME <- 1.0         // time the doors get to close before the car moves
DOOR_GRACE <- 1.0        // extra time before giving up and reopening blocked doors
RETRY_DELAY <- 2.0       // after reopening, wait this long before trying again
BLOCK_PUSH_TIME <- 4.0   // someone standing in the doorway this long gets pushed out
TOP_MIN_WAIT <- 3.0      // the car stays open at the top at least this long
TOP_MAX_WAIT <- 10.0     // and leaves after this long even if someone is still inside
TRAVEL_TIMEOUT <- 15.0   // if an arrival output is ever missed, resend the move input
THINK_INTERVAL <- 0.2

// Car interior relative to the car's origin (the cars are 184 x 200 x 200 units).
CAR_HALF_X <- 92
CAR_HALF_Y <- 100
CAR_FLOOR_Z <- -100
CAR_TOP_Z <- 80
// Doorway relative to the car's origin: the clip (x -128..-103, 112 wide), the landing
// doors (x -102..-98) and the car doors (x -96..-92). A 48-unit player hull overlaps
// one of them anywhere in this box.
DOORWAY_X_MIN <- -152
DOORWAY_X_MAX <- -66
DOORWAY_HALF_Y <- 80
DOOR_PUSH <- Vector(-400, 0, 150)   // out of the car, toward the landing (both landings face -x)

HUD_PRINTCENTER <- 4
SOUND_TICK <- "buttons/blip1.wav"
SOUND_ARRIVE <- "plats/elevbell1.wav"

PrecacheSound(SOUND_TICK)
PrecacheSound(SOUND_ARRIVE)

::Elevators <- []

function FindOrWarn(name)
{
    local ent = Entities.FindByName(null, name)
    if (ent == null)
        printl("[elevators] missing entity: " + name)
    return ent
}

function SetupElevator(n)
{
    local prefix = "elevator" + n
    local car = {
        index = n
        car = FindOrWarn(prefix)
        carDoors = [FindOrWarn(prefix + "_doorleft"), FindOrWarn(prefix + "_doorright")]
        landing = [
            [FindOrWarn(prefix + "_landing_bottom_left"), FindOrWarn(prefix + "_landing_bottom_right")],
            [FindOrWarn(prefix + "_landing_top_left"), FindOrWarn(prefix + "_landing_top_right")]
        ]
        clips = [FindOrWarn(prefix + "_doorway_clip_bottom"), FindOrWarn(prefix + "_doorway_clip_top")]
        closedPos = {}   // door entity index -> local origin when closed
        state = "idle"   // idle, countdown, closing, moving, open_top
        floor = 0        // 0 = lobby, 1 = top; while moving, the floor it is heading to
        timer = 0.0
        since = 0.0
        lastTick = -1
        blockedSince = null
    }
    if (car.car == null)
        return
    // Every door starts closed, so remember where "closed" is before opening any.
    foreach (door in AllDoors(car))
        car.closedPos[door.entindex()] <- door.GetLocalOrigin()
    ::Elevators.append(car)
    OpenDoors(car)
}

function AllDoors(car)
{
    local result = []
    foreach (group in [car.carDoors, car.landing[0], car.landing[1]])
        foreach (door in group)
            if (door != null && door.IsValid())
                result.append(door)
    return result
}

function FloorDoors(car)
{
    local result = []
    foreach (door in [car.carDoors[0], car.carDoors[1], car.landing[car.floor][0], car.landing[car.floor][1]])
        if (door != null && door.IsValid())
            result.append(door)
    return result
}

function SetClip(car, enabled)
{
    local clip = car.clips[car.floor]
    if (clip != null && clip.IsValid())
        EntFireByHandle(clip, enabled ? "Enable" : "Disable", "", 0, null, null)
}

function OpenDoors(car)
{
    SetClip(car, false)
    foreach (door in FloorDoors(car))
        EntFireByHandle(door, "Open", "", 0, null, null)
}

// Only call this with the doorway clear: the clip goes up first so nobody can step back in.
function CloseDoors(car)
{
    SetClip(car, true)
    foreach (door in FloorDoors(car))
        EntFireByHandle(door, "Close", "", 0, null, null)
}

function DoorsClosed(car)
{
    foreach (door in FloorDoors(car))
        if ((door.GetLocalOrigin() - car.closedPos[door.entindex()]).Length() > 1.0)
            return false
    return true
}

function PlayCarSound(car, sound)
{
    EmitSoundEx({ sound_name = sound, entity = car.car, sound_level = 75 })
}

function LivingPlayers()
{
    local result = []
    for (local i = 1; i <= MaxClients().tointeger(); i++)
    {
        local player = PlayerInstanceFromIndex(i)
        if (player != null && player.IsAlive())
            result.append(player)
    }
    return result
}

// Living RED players standing inside the car.
function PlayersInCar(car)
{
    local result = []
    local center = car.car.GetOrigin()
    foreach (player in LivingPlayers())
    {
        if (player.GetTeam() != Constants.ETFTeam.TF_TEAM_RED)
            continue
        local d = player.GetOrigin() - center
        if (fabs(d.x) <= CAR_HALF_X && fabs(d.y) <= CAR_HALF_Y && d.z >= CAR_FLOOR_Z && d.z <= CAR_TOP_Z)
            result.append(player)
    }
    return result
}

// Living players of either team close enough to the doors to block them.
function PlayersInDoorway(car)
{
    local result = []
    local center = car.car.GetOrigin()
    foreach (player in LivingPlayers())
    {
        local d = player.GetOrigin() - center
        if (d.x >= DOORWAY_X_MIN && d.x <= DOORWAY_X_MAX && fabs(d.y) <= DOORWAY_HALF_Y && d.z >= CAR_FLOOR_Z && d.z <= CAR_TOP_Z)
            result.append(player)
    }
    return result
}

// Closes the doors unless someone is in the way. Returns true once closing has started.
function TryClose(car, now)
{
    local blockers = PlayersInDoorway(car)
    if (blockers.len() > 0)
    {
        if (car.blockedSince == null)
            car.blockedSince = now
        foreach (player in blockers)
        {
            ClientPrint(player, HUD_PRINTCENTER, "Stand clear of the doors!")
            if (now - car.blockedSince >= BLOCK_PUSH_TIME)
                player.SetAbsVelocity(DOOR_PUSH)
        }
        return false
    }
    car.blockedSince = null
    CloseDoors(car)
    car.state = "closing"
    car.timer = now + DOOR_TIME
    return true
}

function Depart(car)
{
    car.floor = 1 - car.floor
    car.state = "moving"
    car.since = Time()
    EntFireByHandle(car.car, car.floor == 1 ? "Open" : "Close", "", 0, null, null)
}

function Arrive(car)
{
    OpenDoors(car)
    PlayCarSound(car, SOUND_ARRIVE)
    car.since = Time()
    car.state = car.floor == 1 ? "open_top" : "idle"
}

// Called by the car's OnFullyOpen (top) and OnFullyClosed (lobby) outputs.
function Elevator_OnArrive(n, floor)
{
    foreach (car in ::Elevators)
        if (car.index == n && car.state == "moving" && car.floor == floor)
            Arrive(car)
}

function UpdateElevator(car)
{
    local now = Time()
    switch (car.state)
    {
    case "idle":
        if (PlayersInCar(car).len() > 0)
        {
            car.state = "countdown"
            car.timer = now + DEPART_DELAY
            car.lastTick = -1
        }
        break

    case "countdown":
        local riders = PlayersInCar(car)
        if (riders.len() == 0)
        {
            car.state = "idle"   // everyone stepped out, so don't leave empty
            car.blockedSince = null
            break
        }
        local left = ceil(car.timer - now).tointeger()
        if (left != car.lastTick && left > 0)
        {
            car.lastTick = left
            PlayCarSound(car, SOUND_TICK)
            foreach (player in riders)
                ClientPrint(player, HUD_PRINTCENTER, "Elevator leaving in " + left + "...")
        }
        if (now >= car.timer)
            TryClose(car, now)
        break

    case "closing":
        if (now < car.timer)
            break
        if (DoorsClosed(car))
            Depart(car)
        else if (now >= car.timer + DOOR_GRACE)
        {
            // Something is still in the way: reopen rather than leave with the doors open.
            OpenDoors(car)
            if (car.floor == 0)
            {
                car.state = "countdown"
                car.timer = now + RETRY_DELAY
            }
            else
            {
                car.state = "open_top"
                car.since = now - TOP_MIN_WAIT + RETRY_DELAY
            }
        }
        break

    case "moving":
        if (now - car.since > TRAVEL_TIMEOUT)
        {
            printl("[elevators] elevator" + car.index + " didn't report arriving, sending it again")
            car.since = now
            EntFireByHandle(car.car, car.floor == 1 ? "Open" : "Close", "", 0, null, null)
        }
        break

    case "open_top":
        local waited = now - car.since
        if (waited >= TOP_MAX_WAIT || (waited >= TOP_MIN_WAIT && PlayersInCar(car).len() == 0))
            TryClose(car, now)
        break
    }
}

function ElevatorThink()
{
    foreach (car in ::Elevators)
        UpdateElevator(car)
    return THINK_INTERVAL
}

SetupElevator(1)
SetupElevator(2)
AddThinkToEnt(self, "ElevatorThink")
