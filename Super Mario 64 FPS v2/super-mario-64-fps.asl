state("Super Mario 64 FPS") { }

startup
{
    // Add the ability to split on Collecting the last power star
    settings.Add("bits", true, "Bowser in The Sky");
    settings.Add("cps", true, "Collection the final Power Star", "bits");

    // Add the ability to split for every star
    settings.Add("stars", false, "Collecting Stars");
    for (int i = 1; i <= 104; ++i)
    {
        settings.Add("stars"+i, false, "Collecting "+i+" stars", "stars");
    }

    vars.Weapons = new string[] {
        "Landmine",
        "Shotgun",
        "Poltergust",
        "Sniper",
        "Rocket Launcher",
        "M16"
    };
    settings.Add("guns", false, "Collecting Guns");
    foreach (var weapon in vars.Weapons)
    {
        settings.Add(weapon, false, "Get the " + weapon, "guns");
    }
}

init
{
    //=============================================================================
	// Memory Watcher
	//=============================================================================

    // Add FileStarted and FileLetter watchers
    vars.FileStartedWatchers = new MemoryWatcherList();
    for (int i = 0; i < 4; ++i) {
        vars.FileStartedWatchers.Add(
            new MemoryWatcher<bool>(
                new DeepPointer("UnityPlayer.dll", 0x017B0A90, 0x258, 0x610, 0x60, 0x0 + 0xB8 * i)
            ) { Name = "file"+i }
        );
    }
    vars.FileStartedWatchers.Add(
        new MemoryWatcher<int>(
            new DeepPointer("UnityPlayer.dll", 0x017672D0, 0xE88, 0x390, 0x10, 0x38, 0x20, 0x24)
        ) { Name = "fileLetter"}
    );

    // Add StarCount watcher
    vars.StarCountWatcher = new MemoryWatcher<int>(
        new DeepPointer("UnityPlayer.dll", 0x017AC308, 0xD0, 0x8, 0xC0, 0x84)
    );

    // Add LockControl watchers for BiTS
    vars.LockControlsWatchers = new MemoryWatcherList();
    vars.LockControlsWatchers.Add(
        new MemoryWatcher<bool>(
            new DeepPointer("mono-2.0-bdwgc.dll", 0x00496DE8, 0x420, 0xCE8, 0x16C)
        ) { Name = "lockControls" }
    );
    vars.LockControlsWatchers.Add(
        new MemoryWatcher<float>(
            new DeepPointer("mono-2.0-bdwgc.dll", 0x00496DE8, 0x420, 0xCE8, 0x170)
        ) { Name = "lockControlsTimer" }
    );
    vars.LockControlsWatchers.Add(
        new MemoryWatcher<int>(
            new DeepPointer("UnityPlayer.dll", 0x017AC308, 0xD0, 0x8, 0xC0, 0xD0)
        ) { Name = "currentStageId"}
    );

    // Setup Inventory watchers
    vars.InventoryWatchers = new MemoryWatcherList();

    int inventorySize = 10;
    for (int i = 1; i < inventorySize; ++i)
    {
        vars.InventoryWatchers.Add(
            new MemoryWatcher<int>(
                new DeepPointer("UnityPlayer.dll", 0x017AC308, 0xD0, 0x8, 0xC0, 0x90, 0x20 + 0x4*i)
            ) { Name = "slot"+i }
        );
    }
}

update
{ 
    if (settings["stars"])
    {
        vars.StarCountWatcher.Update(game);
    }
    if (settings["cps"])
    {
        vars.LockControlsWatchers.UpdateAll(game);
    }
    if (settings["guns"])
    {
        vars.InventoryWatchers.UpdateAll(game);
    }
}

start
{
    // Update FileStarted values and get fileLetter
    vars.FileStartedWatchers.ResetAll();
    vars.FileStartedWatchers.UpdateAll(game);
    
    // Checking if we need to start
    return ((vars.FileStartedWatchers["fileLetter"].Current == 65 && !vars.FileStartedWatchers["file0"].Current) || 
            (vars.FileStartedWatchers["fileLetter"].Current == 66 && !vars.FileStartedWatchers["file1"].Current) || 
            (vars.FileStartedWatchers["fileLetter"].Current == 67 && !vars.FileStartedWatchers["file2"].Current) || 
            (vars.FileStartedWatchers["fileLetter"].Current == 68 && !vars.FileStartedWatchers["file3"].Current));
}

split
{
    // Split for every star collected. StarCount is updated then the game saves the data (about 0.75 seconds after fade-out)
    bool starCounting_enabled = settings["stars"];
    if (starCounting_enabled)
    {
        for (int i = 1; i <= 104; ++i)
        {
            // Check if current StarCount has to be splitted on
            bool starCount_enabled = settings["stars"+i];
            if (starCount_enabled && vars.StarCountWatcher.Current == i && vars.StarCountWatcher.Changed)
            {
                return true;
            }
        }
    }

    // Stage 35 is BiTS, controls get locked when touching a star, but also when touching an Amp. Amp's also have a custom LockTime whereas star's do not
    bool collectPowerStar_enabled = settings["cps"];
    if (collectPowerStar_enabled && vars.LockControlsWatchers["currentStageId"].Current == 35)
    {
        if (vars.LockControlsWatchers["lockControls"].Current && 
            vars.LockControlsWatchers["lockControls"].Changed && 
            vars.LockControlsWatchers["lockControlsTimer"].Current <= 0 && 
            !vars.LockControlsWatchers["lockControlsTimer"].Changed)
        {
            return true;
        }
    }

    bool collectGuns_enabled = settings["guns"];
    if (collectGuns_enabled) {
        // Loop over inventory and check if a new weapon is added
        foreach (var watcher in vars.InventoryWatchers)
        {
            // offset by 2, because none (0) and pistol (1) aren't used
            if (watcher.Changed && watcher.Current != 0 && settings[vars.Weapons[watcher.Current-2]])
            {
                return true;
            }
        }
    }
}