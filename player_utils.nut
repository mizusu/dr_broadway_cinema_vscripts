::IsValidPlayer <- function(player)
{
    try
    {
        return player != null && player.IsValid() && player.IsPlayer() && player.GetTeam() > 1;
    }
    catch(e)
    {
        return false;
    }
}

function GetAllValidPlayers()
{
    for (local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (IsValidPlayer(player))
            yield player;
    }
    return null;
}

// Getting the userid from a player handle
// Note:
// For games other than Team Fortress 2, replace tf_player_manager with the manager classname for your game. E.g. cs_player_manager in or dod_player_manager
// Receives a player handle (CBaseEntity) and returns their integer userid.
// Returns integer userid, or -1 if not found.
function GetUserIDFromPlayerHandle(playerHandle) {
	// ::PlayerManager <- Entities.FindByClassname(null, "tf_player_manager")
	local playerManager = Entities.FindByClassname(null, "tf_player_manager");

    if (playerManager == null) {
        print("PlayerManager entity not found.");
        return -1;
    }

    return NetProps.GetPropIntArray(playerManager, "m_iUserID", playerHandle.entindex());
}

// For gettin player via userID, simply call TF's built-in function:
// CTFPlayer GetPlayerFromUserID(int userid) Given a user id, return the entity, or null.

/* Iterating Through Players */

// It can be useful to iterate through players only. However, doing this with Entities.FindByClassname() is inefficient as it needs to search every entity. A quirk can be utilised to efficiently iterate players. Each networked entity has an associated 'entity index', which ranges from 0 to MAX_EDICTS. Usually these are unpredictable, however there is 2 groups of entities that have reserved entity indexes: worldspawn and players. Worldspawn is always reserved at entity index 0, and players are reserved from entity index 1 to maxplayers + 1. Using this fact, players can be simply iterated like shown below:
// Note:
// The old way of iterating players was using Constants.FServers.MAX_PLAYERS. This is no longer recommended. Instead use MaxClients().tointeger() as shown below (only needs to be defined once in any file). MaxClients() only iterates the player limit set in the server rather than the maximum possible amount, which is more efficient, especially now that
// supports 100 players, but most servers will only be 24/32!
function MaxClients()
{
	::MaxPlayers <- MaxClients().tointeger()

	for (local i = 1; i <= MaxPlayers; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		printl(player)
	}
}

// Moving a player into spectating state without death

// Avoids death effects such as kill feed or screams from appearing if killed by conventional means, and the player still remains on the team.
// Todo: Doesn't work right in Counter-Strike: Source
function ForceSpectate(player)
{
	NetProps.SetPropInt(player, "m_iObserverLastMode", 5)
	local team = player.GetTeam()
	NetProps.SetPropInt(player, "m_iTeamNum", 1)
	player.DispatchSpawn()
	NetProps.SetPropInt(player, "m_iTeamNum", team)
}
