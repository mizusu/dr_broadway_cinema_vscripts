// Some TF2 Bot Commands

// tf_bot_warp_team_to_me 
// tf_bot_add 4 red easy
// tf_bot_kick all
// mp_teams_unbalance_limit 10
// sv_cheats 1
// developer 1
// mp_disable_respawn_times 1

// Methods that exist:
// GetPlayerFromUserID (native function)

// Methods that DON'T exist:
// GetPlayerCount
// GetPlayerName
// GetPlayerUserId

bluMultikillSoundToggle <- 0;
lastREDDeathDateTime <- {};
playerDeathCounter <- 0;

playerMultikillStartTime <- {};
playerMultikillEndTime <- {};

previousREDPlayerDeathTime <- {};

a <- 5               // creates a table slot in this table
b <- "A text string" // creates a table slot in this table
::x <- 10            // creates a table slot in the root table

::PlayerManager <- Entities.FindByClassname(null, "tf_player_manager");

hostPlayer <- null;
currentPlayersTable <- {};
currentPlayersArray <- [];

myTime <- {};

function helloWorld() {
    // IterateThroughPlayers();

    // printl("IsPlayerAlive: " + IsPlayerAlive(hostPlayer));
    // printl("currentPlayersTable: " + currentPlayersTable);
    // printl("currentPlayersArray: " + currentPlayersArray);
    // printl("currentPlayersArray.len: " + currentPlayersArray.len());

    // printl(Time());
    // printl(EntFire);
    // printl(EntFireByHandle);

    // FireBluMultikill();
    player_dies();

    // DeepPrintTable( getroottable() );
}

function OnScriptHook_OnTakeDamage2(params)
{
    printl("OnScriptHook_OnTakeDamage");

    // Make player take no damage
    if (params.const_entity.IsPlayer())
    {
        printl(params);
        params.damage = 0;
    }
}

function OnScriptHook_OnTakeDamage(params)
{
    // printl("OnScriptHook_OnTakeDamage" + params);
}

function OnGameEvent_player_spawn(params)
{
    // printl("OnGameEvent_player_spawn");
}

// The event "post_inventory_application" is sent when a player gets a whole new set of items, aka touches a resupply locker / respawn cabinet or spawns in.
function OnGameEvent_post_inventory_application(params)
{
    printl("OnGameEvent_post_inventory_application");
	local player = GetPlayerFromUserID(params.userid)

	// add uber protection to the player for 2 seconds.
	player.AddCondEx(52, 2.0, null)
}

// The event "post_inventory_application" is sent when a player gets a whole new set of items, aka touches a resupply locker / respawn cabinet or spawns in.
function OnGameEvent_player_death(params)
{
    // printl("OnGameEvent_player_death" + params);
    // printl(params);
    // printl(params.userid);
    
    player_dies();
}

function OnGameEvent_player_say(params)
{
    printl("OnGameEvent_player_say" + params);
}

function OnGameEvent_player_disconnect(params)
{
    printl("OnGameEvent_player_say" + params);
}

function OnGameEvent_round_start(params)
{
    printl("OnGameEvent_round_start" + params);
}

function OnGameEvent_round_end(params)
{
    printl("OnGameEvent_round_end" + params);
    // ClearGameEventCallbacks();
}

::DeepPrintTable <- function( debugTable, prefix = "" )
{
	if (prefix == "")
	{
		printl(prefix + debugTable)
		printl("{")
		prefix = "   "
	}
	foreach (idx, val in debugTable)
	{
		if (typeof(val) == "table")
		{
			printl( prefix + idx + " = \n" + prefix + "{")
			DeepPrintTable( val, prefix + "   " )
			printl(prefix + "}")
		}
		else if (typeof(val) == "string")
			printl(prefix + idx + "\t= \"" + val + "\"")
		else
			printl(prefix + idx + "\t= " + val)
	}
	if (prefix == "   ")
		printl("}")
}

::GetPlayerUserID <- function(player)
{
    return NetProps.GetPropIntArray(PlayerManager, "m_iUserID", player.entindex());
}

function IterateThroughPlayers()
{
    for (local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        // currentPlayersTable.player = player;
        hostPlayer = player;

        if (player == null){
            continue   
        }
        else {
            currentPlayersArray.push(player);
        }

        printl("typeof(player): " + typeof(player));
    }
}

::IsPlayerAliveOriginal <- function(player)
{
    // lifeState corresponds to the following values:
    // 0 - alive
    // 1 - dying (probably unused)
    // 2 - dead
    // 3 - respawnable (spectating)
    return NetProps.GetPropInt(player, "m_lifeState") == 0;
}

::IsPlayerAlive <- function(player)
{
    // lifeState corresponds to the following values:
    // 0 - alive
    // 1 - dying (probably unused)
    // 2 - dead
    // 3 - respawnable (spectating)
    return NetProps.GetPropInt(player, "m_lifeState");
}

function FireBluMultikill()
{
    // printl("LocalTime: " + LocalTime);
    // printl("Time: " + Time);
    // printl("Time(): " + Time());

    // LocalTime(myTime);
    // foreach(prop, value in myTime) {
    //     printl("prop: " + prop);
    //     printl("type: " + type(value));
    //     printl("value: " + value);
    //     printl("\n");
    // }

    if (bluMultikillSoundToggle == 0) {
        // Works:
        EntFire("sound_blu_multikill1", "PlaySound", null, 0, !self);
        bluMultikillSoundToggle = 1;
    }
    else {
        // Works:
        EntFire("sound_blu_multikill2", "PlaySound", null, 0, !self);
        bluMultikillSoundToggle = 0;
    }
    
    // Does not work:
    // EntFireByHandle("sound_blu_multikill1","PlaySound", null, 0, !self, !self);
}

function player_dies()
{
    playerDeathCounter = playerDeathCounter + 1;
    printl("playerDeathCounter: " + playerDeathCounter);

    if (isTableEmpty(previousREDPlayerDeathTime)) {
        LocalTime(previousREDPlayerDeathTime);
        return;
    }

    local currentTime = {};
    LocalTime(currentTime);

    local secondsElapsed = getSecondsElapsed(previousREDPlayerDeathTime, currentTime);
    printl("secondsElapsed: " + secondsElapsed);

    if (secondsElapsed > 2) {
        printl("Too much time has elapsed between the kills. Resetting...");

        // Reset.
        playerDeathCounter = 0;
        previousREDPlayerDeathTime = currentTime;
        return;
    }
    else {
        if (playerDeathCounter > 3) {
            printl("Firing multikill sound. Resetting...");
            // Fire multikill sound.
            FireBluMultikill();
    
            // Reset.
            playerDeathCounter = 0;
            previousREDPlayerDeathTime = currentTime;
        }
    }
}


function getSecondsElapsed(startTime, endTime) {
    local startSeconds = startTime.hour * 3600 + startTime.minute * 60 + startTime.second;
    local endSeconds = endTime.hour * 3600 + endTime.minute * 60 + endTime.second;

    return endSeconds - startSeconds;
}

function isTableEmpty(table) {
    foreach(prop, value in table) {
        return false; // If there is at least one key, then the table is not empty
    }
    return true; // If the loop finishes, then the table is empty
  }

__CollectGameEventCallbacks(this);