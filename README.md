Allows you to save your ongoing runs.  
Saves at the start of each stage (does not save the stage layout or variant).  

Disabled in online play and local coop.  

### Custom data callbacks
```lua
-- Callback functions for both should have a single parameter
-- `data` - The custom data table for the current file
    -- This is shared between all mods using this; create a new subtable for your namespace!

Callback.find("save", "saveMod")    -- Runs on file save
Callback.find("load", "saveMod")    -- Runs on file load
```

---

### Installation Instructions
Install through the Thunderstore client or r2modman [(more detailed instructions here if needed)](https://return-of-modding.github.io/ModdingWiki/Playing/Getting-Started/).  
Join the [Return of Modding server](https://discord.gg/VjS57cszMq) for support.  