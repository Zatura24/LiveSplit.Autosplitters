state("Super Mario 64 FPS") { }

startup
{
    //=============================================================================
	// Settings
	//=============================================================================
    // Add the ability to split on Collecting the last power star
    settings.Add("bowser", true, "Defeating Bowser");
    settings.Add("BiTDW", false, "Collecting the first key in BiTDW", "bowser");
    settings.Add("BiTFS", false, "Collecting the second key in BiTFS", "bowser");
    settings.Add("BiTS", true, "Collecting the final Power Star in BiTS", "bowser");

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

    // Add the ability to split for every star
    settings.Add("stars", false, "Collecting Stars");
    for (int i = 1; i <= 104; ++i)
    {
        settings.Add("stars"+i, false, "Collecting "+i+" stars", "stars");
    }

    //=============================================================================
	// Functions
	//=============================================================================
    vars.OldKeyCount = 0;
    vars.CountKeys = (Func<bool[], int>) ((keys) => {
        int count = 0;
        for(int i = 0; i < keys.Length; ++i) {
            count += keys[i] ? 1 : 0;
        }
        return count;
    });
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

    // Add Bowser watchers for BiTS, BiTDW and BiTFS
    vars.LockControlWatchers = new MemoryWatcherList();
    vars.LockControlWatchers.Add(
        new MemoryWatcher<bool>(
            new DeepPointer("mono-2.0-bdwgc.dll", 0x00496DE8, 0x420, 0xCE8, 0x16C)
        ) { Name = "lockControls" }
    );
    vars.LockControlWatchers.Add(
        new MemoryWatcher<float>(
            new DeepPointer("mono-2.0-bdwgc.dll", 0x00496DE8, 0x420, 0xCE8, 0x170)
        ) { Name = "lockControlsTimer" }
    );
    vars.LockControlWatchers.Add(
        new MemoryWatcher<int>(
            new DeepPointer("UnityPlayer.dll", 0x017AC308, 0xD0, 0x8, 0xC0, 0xD0)
        ) { Name = "currentStageId"}
    );
    current.KeyArray = new bool[8];
    vars.KeyArrayStart = IntPtr.Zero;

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
    if (settings["BiTS"])
    {
        vars.LockControlWatchers.UpdateAll(game);
    }
    if (settings["BiTDW"] || settings["BiTFS"]) {
        for (int i = 0; i < (current.KeyArray.Length/2); ++i) {
            current.KeyArray[i*2] = game.ReadValue<bool>((IntPtr)vars.KeyArrayStart + 0xB8 * i);
            current.KeyArray[i*2+1] = game.ReadValue<bool>((IntPtr)vars.KeyArrayStart + 0xB8 * i + 1);
        }
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

    // Wait until the game is booted before setting key pointer
    if (vars.KeyArrayStart == IntPtr.Zero) {
        IntPtr KeyArrayStart;
        new DeepPointer("UnityPlayer.dll", 0x017B0A90, 0x258, 0x610, 0x60, 0x83).DerefOffsets(game, out KeyArrayStart);
        vars.KeyArrayStart = KeyArrayStart;
    }
    
    // Checking if we need to start
    vars.OldKeyCount = vars.CountKeys(current.KeyArray);
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
    bool collectPowerStar_enabled = settings["BiTS"]; // Stage 35
    if (collectPowerStar_enabled && vars.LockControlWatchers["currentStageId"].Current == 35)
    {
        if (vars.LockControlWatchers["lockControls"].Current && 
            vars.LockControlWatchers["lockControls"].Changed && 
            vars.LockControlWatchers["lockControlsTimer"].Current <= 0 && 
            !vars.LockControlWatchers["lockControlsTimer"].Changed)
        {
            return true;
        }
    }

    // Split when the amount of keys has changed, meaning a key has been picked up
    bool collectKeyOne_enabled = settings["BiTDW"];
    bool collectKeyTwo_enabled = settings["BiTFS"];
    if (collectKeyOne_enabled || collectKeyTwo_enabled) {
        int KeyCount = vars.CountKeys(current.KeyArray);
        if (KeyCount != vars.OldKeyCount) {
            vars.OldKeyCount = KeyCount;
            return true;
        }
    }

    // Split when collecting a gun by checking every slot in the inventory
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