// Automatic elevators, run by the map's `elevator_logic` logic_script.
//
// Each car waits at the lobby with its doors open. When a living RED player
// steps in, a countdown starts; then the car and landing doors close and the
// car rides up. At the top the doors open, and once the car is empty (or after
// TOP_MAX_WAIT seconds) it closes up and returns to the lobby by itself.
// There are no buttons, so nobody can send a car up empty or grief it.
//
// Map entities per car N (see CLAUDE.md):
//   elevatorN                         func_tracktrain (max speed = its startspeed key)
//   elevatorN_track_origin            path_track at the lobby (start of the path)
//   elevatorN_track_destination       path_track at the top (dead end, so the car stops there)
//   elevatorN_doorleft / _doorright   car doors, parented to the car
//   elevatorN_landing_bottom_left/_right, elevatorN_landing_top_left/_right
//                                     landing doors in the shaft frames, closed while the car is away
// Both path_tracks have OnPass -> elevator_logic RunScriptCode Elevator_OnArrive(N, floor),
// with floor 0 = lobby and 1 = top.

DEPART_DELAY <- 5.0   // seconds from the first RED stepping in until the doors close
DOOR_TIME <- 1.0   // time for the doors to close before the car moves
TOP_MIN_WAIT <- 3.0   // the car stays open at the top at least this long
TOP_MAX_WAIT <- 10.0  // and leaves after this long even if someone is still inside
TRAVEL_TIMEOUT <- 15.0 // failsafe if an arrival output is ever missed
THINK_INTERVAL <- 0.2

// Car interior relative to the train's origin (the cars are 184 x 200 x 200 units).
CAR_HALF_X <- 92
CAR_HALF_Y <- 100
CAR_FLOOR_Z <- -100
CAR_TOP_Z <- 80

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
        train = FindOrWarn(prefix)
        carDoors = [FindOrWarn(prefix + "_doorleft"), FindOrWarn(prefix + "_doorright")]
        landing = [
            [FindOrWarn(prefix + "_landing_bottom_left"), FindOrWarn(prefix + "_landing_bottom_right")],
            [FindOrWarn(prefix + "_landing_top_left"), FindOrWarn(prefix + "_landing_top_right")]
        ]
        state = "idle"   // idle, countdown, closing, moving, open_top, closing_top
        floor = 0        // 0 = lobby, 1 = top; while moving, the floor it is heading to
        timer = 0.0
        since = 0.0
        lastTick = -1
    }
    if (car.train == null)
        return
    ::Elevators.append(car)
    OpenDoors(car)
}

function FireAll(ents, input)
{
    foreach (ent in ents)
        if (ent != null && ent.IsValid())
            EntFireByHandle(ent, input, "", 0, null, null)
}

function OpenDoors(car)
{
    FireAll(car.carDoors, "Open")
    FireAll(car.landing[car.floor], "Open")
}

function CloseDoors(car)
{
    FireAll(car.carDoors, "Close")
    FireAll(car.landing[car.floor], "Close")
}

function PlayCarSound(car, sound)
{
    EmitSoundEx({ sound_name = sound, entity = car.train, sound_level = 75 })
}

// Living RED players standing inside the car.
function PlayersInCar(car)
{
    local result = []
    local center = car.train.GetOrigin()
    for (local i = 1; i <= MaxClients().tointeger(); i++)
    {
        local player = PlayerInstanceFromIndex(i)
        if (player == null || !player.IsAlive() || player.GetTeam() != Constants.ETFTeam.TF_TEAM_RED)
            continue
        local d = player.GetOrigin() - center
        if (fabs(d.x) <= CAR_HALF_X && fabs(d.y) <= CAR_HALF_Y && d.z >= CAR_FLOOR_Z && d.z <= CAR_TOP_Z)
            result.append(player)
    }
    return result
}

function Depart(car)
{
    car.floor = 1 - car.floor
    car.state = "moving"
    car.since = Time()
    EntFireByHandle(car.train, car.floor == 1 ? "StartForward" : "StartBackward", "", 0, null, null)
}

function Arrive(car)
{
    EntFireByHandle(car.train, "Stop", "", 0, null, null)
    OpenDoors(car)
    PlayCarSound(car, SOUND_ARRIVE)
    car.since = Time()
    car.state = car.floor == 1 ? "open_top" : "idle"
}

// Called by the path_tracks' OnPass outputs.
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
        {
            CloseDoors(car)
            car.state = "closing"
            car.timer = now + DOOR_TIME
        }
        break

    case "closing":
    case "closing_top":
        if (now >= car.timer)
            Depart(car)
        break

    case "moving":
        if (now - car.since > TRAVEL_TIMEOUT)
        {
            printl("[elevators] elevator" + car.index + " arrival timed out, forcing it")
            Arrive(car)
        }
        break

    case "open_top":
        local waited = now - car.since
        if (waited >= TOP_MAX_WAIT || (waited >= TOP_MIN_WAIT && PlayersInCar(car).len() == 0))
        {
            CloseDoors(car)
            car.state = "closing_top"
            car.timer = now + DOOR_TIME
        }
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
