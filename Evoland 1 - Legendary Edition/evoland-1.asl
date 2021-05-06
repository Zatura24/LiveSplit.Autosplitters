state("Evoland")
{
    int x_pos :             "directx.hdll", 0x00009DAC, 0xC, 0x94, 0x94, 0xC, 0x30, 0x18;
    int y_pos :             "directx.hdll", 0x00009DAC, 0xC, 0x94, 0x68, 0xC4, 0xC, 0x30, 0x1C;
    int dialog_line_index : "directx.hdll", 0x00009DAC, 0xC, 0x94, 0x94, 0xC, 0x4C, 0x8, 0x1C, 0xC, 0x8, 0xC, 0x8, 0xC, 0x14, 0x8, 0x0;
}

startup
{
    // Available splits; {<key>,<x,y[,x_offset,y_offset]>}
    vars.POSITION_SPLITS = new Dictionary<string, int[]>() 
    {
        { "start",              new int[2] { 12, 52 } },
        { "overworld",          new int[2] { 79, 63 } },
        { "village",            new int[2] { 42, 27 } },
        { "villageExit",        new int[2] { 87, 40 } },
        { "crystalCaves",       new int[2] { 24, 77 } },
        { "crystalCavesExit",   new int[2] { 10, 8 } },
        { "forestExit",         new int[2] { 79, 73 } },
        { "noriaMines",         new int[2] { 47, 67 } },
        { "noriaMinesExit",     new int[2] { 75, 84 } },
        { "aogaiVillage",       new int[2] { 9, -16 } },
        { "aogaiVillageExit",   new int[4] { 8, -19, 1, 0 } },
        { "sacredGrove",        new int[2] { 12, 38 } },
        { "sacredGroveExit",    new int[2] { 47, 44 } },
        { "ruinsOfSarudnahk",   new int[2] { 12, 125 } },
        { "blackCitadel",       new int[2] { 118, 88 } },
        { "manaTree",           new int[2] { 115, 76 } }
    };

    // Available settings
    settings.Add("overworld",               false, "Entering the Overworld");
    settings.Add("village",                 false, "Picking up the village chest");
    settings.Add("villageExit",             false, "Exiting the village at the top");
    settings.Add("crystalCaves",            false, "Entering Crystal Caves");
    settings.Add("crystalCavesExit",        false, "Exiting the Crystal Caves after the Kafka fight");
    settings.Add("forestExit",              false, "Exiting the forest before entering Noria Mines");
    settings.Add("noriaMines",              false, "Entering Noria Mines");
    settings.Add("noriaMinesExit",          false, "Exiting Noria Mines after the Dark Clink fight");
    settings.Add("aogaiVillage",            false, "Entering Aogai Village from the bottom");
    settings.Add("aogaiVillageExit",        false, "Exiting Aogai Village at the bottom");
    settings.Add("sacredGrove",             false, "Entering the Sacred Grove");
    settings.Add("sacredGroveExit",         false, "Exiting the Sacred Grove at the bottom");
    settings.Add("ruinsOfSarudnahk",        false, "Entering the Ruins of Sarudnahk");
    settings.Add("ruinsOfSarudnahkPortal",  false, "Entering the portal in the Ruins of Sarudnahk");
    settings.Add("blackCitadel",            false, "Entering the Black Citadel");
    settings.Add("manaTree",                false, "Entering the Mana Tree");

    // Define variables at script startup
    vars.dialog = 0;
    vars.visited_splits = new List<string>(vars.POSITION_SPLITS.Count);

    vars.isAtLocation = (Func<string, int, int, bool>) ((location, x, y) => 
    {
        var stored_position = vars.POSITION_SPLITS[location];

        // Location can have an offset, this has to be checked grid like
        if (stored_position.Length > 2)
        {
            for (int i = stored_position[0] - stored_position[2]; i <= stored_position[0] + stored_position[2]; i++)
            {
                for (int j = stored_position[1] - stored_position[3]; j <= stored_position[1] + stored_position[3]; j++)
                {
                    if (x == i && y == j) {
                        return true;
                    }
                }
            }
            return false;
        } else {
            return x == stored_position[0] 
                && y == stored_position[1];
        }
    });
}

start
{
    // Reset variables before starting
    vars.dialog = 0;
    vars.visited_splits.Clear();

    // Start the timer when player is at starting position
    if (vars.isAtLocation("start", current.x_pos, current.y_pos))
    {
        return true;
    }
}

update
{
    // Increase dialog count in final fight (split 9)
    // Pointer sometimes becomes assigned, therefor check for 1 instead of 0
    if (vars.isAtLocation("manaTree", current.x_pos, current.y_pos ) 
        && current.dialog_line_index == 1 
        && current.dialog_line_index != old.dialog_line_index)
    {
        vars.dialog++;
    }
}

split
{
    int x = current.x_pos;
    int y = current.y_pos;

    // Loop through all the location to split on
    foreach (var keyValue in vars.POSITION_SPLITS)
    {
        if (keyValue.Key == "start") { continue; }

        bool splitEnabled = settings[keyValue.Key];
        bool visitedLocation = vars.visited_splits.Contains(keyValue.Key);
        bool atLocation = vars.isAtLocation(keyValue.Key, x, y);
        
        if (splitEnabled && !visitedLocation && atLocation)
        {
            vars.visited_splits.Add(keyValue.Key);
            return true;
        }
    }
        
    // Closing final textbox (address gets removes from memory, thus becomming 0); dialog 5 is the last dialog.
    if (vars.isAtLocation("manaTree", x, y) 
        && vars.dialog == 5
        && current.dialog_line_index == 0
        && old.dialog_line_index == 4)
    {
        return true;
    }
}