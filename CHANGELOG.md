### v1.0.8
* Fixed off-by-one error in "Stages Completed" on the stats screen.
* Fixed incorrect skill saving for skills that are changed (e.g., Sniper's Z and V)

### v1.0.7
* Updated alongside RMT.
* Now saves skill identifiers instead of ID numbers (which is prone to change depending on mods loaded).
* Now sets active artifacts properly again.

### v1.0.6
* Replaced lua syntax array accessing with gm.array_get

### v1.0.5
* Changed ImGui window to use radio buttons instead
* Reduced memory usage (I think)
* Change: Temporary items are now saved
* Fix: Crash when loading files with items that create RMT custom objects
* Fix: Now shows the correct survivor on results screen
* Fix: Should no longer throw an error when there are too many save files

### v1.0.4
* Should no longer crash on pressing "Try Again"

### v1.0.3
* Fix: Sniper runs are no longer softlocked if you enter a new stage and quit before reloading
    * The "Reload" skill got saved instead of "Snipe"
    
### v1.0.2
* ! Does not load existing files from previous versions !
* Change: Gold you manage to sneak into the next stage is now saved
* Change: Items now load in order of acquiry
* Fix: Artifacts now toggle correctly
* Fix: Enemy and chest scaling no longer reset
* Fix: HP gained from Infusion is now saved
* Fix: Equipment is now saved
* Fix: Triggering OSP from OSP mod no longer deletes the save file
* Fix: Drones are now saved
* Fix: Selected skin is now saved

### v1.0.1
* Fixed some things not loading.
* Added short explanation text for usage in-game.

### v1.0.0
* Initial release