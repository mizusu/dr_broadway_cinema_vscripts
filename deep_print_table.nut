// This function is a slightly edited variant of the one in L4D2 (g_ModeScript.DeepPrintTable())
// View class instances's functions using instance.getclass() [returns table]
// In Squirrel 3, view extra function information like argument count; use function.getinfos() / nativefunction.getinfos() [returns table]
function DeepPrintTable( debugTable, prefix = "" )
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