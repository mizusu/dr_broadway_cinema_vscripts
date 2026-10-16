// Stand-in for the lost original. Included by create_cbs.nut and create_following_bot.nut.
// TODO: track damage to the ambient "patron" NPCs and spawn the CBS boss when they're killed.

// Called from OnScriptHook_OnTakeDamage with the hook's params table.
// Global (::) so it can be reached from the bots' nested script scopes.
::recordPatronDamage <- function(params)
{
}
