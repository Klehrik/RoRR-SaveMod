-- SaveMod

mods["LuaENVY-ENVY"].auto()
mods["ReturnsAPI-ReturnsAPI"].auto{
    namespace   = "saveMod",
    mp          = true  -- Safe because it's disabled online
}

Initialize.add_hotloadable(Callback.Priority.BEFORE, function()
    require("./ui/element")
    require("./ui/queue")
    require("./ui/mouse")
    require("./core/util")
    require("./core/saves")
    require("./core/render")
end)

_is_loading = false


-- ========== Hooks ==========

-- Reset slot selection
Hook.add_post("gml_Object_oSelectMenu_Create_0", function(self, other)
    __current = 0
end)

-- Load survivor from slot
local run_start_hook_setup
run_start_hook_setup = Hook.add_post(gm.constants.__input_system_tick, function(self, other, result, args)
    -- Run this hook until oSelectMenu exists, then
    -- add a hook for `run_start` and remove this one
    local d = Instance.find(gm.constants.oSelectMenu)
    if Instance.exists(d) then
        run_start_hook_setup:remove()
        
        -- `run_start`
        Hook.add_pre(gm.constants[d.run_start.script_name], function(self, other)
            load_survivor_from_slot(self)
        end)
    end
end)

-- Load artifacts from slot
Hook.add_post(gm.constants.game_lobby_apply_rules, function(self, other, result, args)
    load_artifacts_from_slot()
end)

-- Load stage from slot
Hook.add_pre(gm.constants.stage_goto, function(self, other, result, args)
    if (not self) or (self.object_index ~= gm.constants.oSelectMenu) then return end
    local stage, variant = load_stage_from_slot(self)
    if stage then
        args[1].value = stage
        args[2].value = variant
    end
end)

-- Load the rest from slot
Hook.add_post("gml_Object_oDirectorControl_Other_4", function(self, other)
    if self.stages_passed > 0 then return end
    load_from_slot(self)
end)

-- Save to slot
Hook.add_post(gm.constants.stage_goto, function(self, other, result, args)
    if (not self) or (not self.stages_passed) then return end
    save_to_slot(self)
end)

-- Delete save on defeat/victory
Hook.add_post(gm.constants.actor_set_dead, function(self, other, result, args)
    if args[1].value:get_object_index() ~= gm.constants.oP then return end
    delete_save()
end)
Hook.add_post("gml_Object_oCommandFinal_Alarm_0", function(self, other)
    delete_save()
end)

-- Crash involving the Tempus artifact pickup when loading on ToTE (introduced in v1.1.6)
-- I don't know how to fix this so just destroy it for now
Hook.add_pre("gml_Object_oTimedArtifact_Create_0", function(self, other)
    local hud = Instance.find(gm.constants.oHUD)
    if not hud.minute then
        gm.instance_destroy(gm.constants.oTimedArtifact)
        return false
    end
end)


-- ========== Public Methods ==========

function public.is_loading()
    return _is_loading
end