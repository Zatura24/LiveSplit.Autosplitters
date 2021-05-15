state("Super Mario 64 FPS")
{
    int fileLetter      : "UnityPlayer.dll", 0x017672D0, 0xE88, 0x390, 0x10, 0x38, 0x20, 0x24;
    bool aFileStarted   : "UnityPlayer.dll", 0x017B0A90, 0x258, 0x610, 0x60, 0x0;
    bool bFileStarted   : "UnityPlayer.dll", 0x017B0A90, 0x258, 0x610, 0x60, 0xB8;
    bool cFileStarted   : "UnityPlayer.dll", 0x017B0A90, 0x258, 0x610, 0x60, 0x170;
    bool dFileStarted   : "UnityPlayer.dll", 0x017B0A90, 0x258, 0x610, 0x60, 0x228;

    int starCount       : "UnityPlayer.dll", 0x017AC308, 0xD0, 0x8, 0xC0, 0x84;
    int currentStageId  : "UnityPlayer.dll", 0x017AC308, 0xD0, 0x8, 0xC0, 0xD0;

    bool lockControls   : "mono-2.0-bdwgc.dll", 0x00496DE8, 0x420, 0xCE8, 0x16C;
    float lockControlsTimer : "mono-2.0-bdwgc.dll", 0x00496DE8, 0x420, 0xCE8, 0x170;
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
    // Split for every star collected. StarCount is updated then the game saves the data (about 0.75 seconds after fade-out)
    for (int i = 1; i < 100; i++) {
        // Check if current StarCount has to be splitted on
        bool starCount_enabled = settings[""+i];

        if (starCount_enabled) {
            if (current.starCount == i && old.starCount != current.starCount) {
                return true;
            }
        }
    }

    // Stage 35 is BiTS, controls get locked when touching a star, but also when touching an Amp. Amp's also have a custom LockTime where star's don't
    if (current.currentStageId == 35) {
        if (current.lockControls && current.lockControls != old.lockControls && current.lockControlsTimer <= 0 && current.lockControlsTimer == old.lockControlsTimer){
            return true;
        }
    }
}