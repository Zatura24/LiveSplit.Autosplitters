state("Super Mario 64 FPS")
{
    // bool isAtMainMenu   : "mono-2.0-bdwgc.dll", 0x4A1CA5; // need to find a good pointer for thisw 
    int fileLetter      : "UnityPlayer.dll",    0x017672D0, 0xE88, 0x390, 0x10, 0x38, 0x20, 0x24;
    bool aFileStarted   : "UnityPlayer.dll",    0x017B0A90, 0x258, 0x610, 0x60, 0x0;
    bool bFileStarted   : "UnityPlayer.dll",    0x017B0A90, 0x258, 0x610, 0x60, 0xB8;
    bool cFileStarted   : "UnityPlayer.dll",    0x017B0A90, 0x258, 0x610, 0x60, 0x170;
    bool dFileStarted   : "UnityPlayer.dll",    0x017B0A90, 0x258, 0x610, 0x60, 0x228;
    int star_count      : "UnityPlayer.dll", 0x017AC308, 0xD0, 0x8, 0xC0, 0x84;
}

update {
    print("stars: " + current.star_count);
}

startup
{
    // Add the ability to split for every star
    for (int i = 1; i < 100; i++) {
        settings.Add(""+i, false, "Collecting "+i+" stars");
    }
}

start
{
    // Start the timer when a save file is selected
    if ((current.fileLetter == 65 && !current.aFileStarted) || 
        (current.fileLetter == 66 && !current.bFileStarted) || 
        (current.fileLetter == 67 && !current.cFileStarted) || 
        (current.fileLetter == 68 && !current.dFileStarted)) {
        return true;
    }
}

split
{
    for (int i = 1; i < 100; i++) {
        bool star_count_enabled = settings[""+i];

        if (star_count_enabled) {
            if (current.star_count == i && old.star_count != current.star_count) {
                return true;
            }
        }
    }
}

// reset
// {
//     if (current.isAtMainMenu && current.isAtMainMenu != old.isAtMainMenu) {
//         return true;
//     }
// }